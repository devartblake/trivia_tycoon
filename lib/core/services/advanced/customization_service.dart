import 'dart:async';
import 'package:flutter/material.dart';
import 'gift_transaction_service.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

class CustomizationService extends ChangeNotifier {
  static final CustomizationService _instance =
      CustomizationService._internal();
  factory CustomizationService() => _instance;
  CustomizationService._internal();

  // Storage
  final Map<String, Set<String>> _ownedThemes = {};
  final Map<String, Set<String>> _ownedStickerPacks = {};
  final Map<String, String> _activeThemes = {};
  final Map<String, Map<String, dynamic>> _userPreferences = {};

  // Streams
  final Map<String, StreamController<String>> _themeStreams = {};
  final Map<String, StreamController<Set<String>>> _stickerStreams = {};

  void initialize() {
    _loadDefaultItems();
    LogManager.debug('CustomizationService initialized');
  }

  void dispose() {
    for (final controller in _themeStreams.values) {
      controller.close();
    }
    for (final controller in _stickerStreams.values) {
      controller.close();
    }
    _themeStreams.clear();
    _stickerStreams.clear();
    super.dispose();
  }

  // ============ Theme Management ============

  Future<bool> purchaseTheme(String userId, String themeId, int price) async {
    // Check if already owned
    if (ownsTheme(userId, themeId)) {
      LogManager.debug('Theme already owned');
      return false;
    }

    // Deduct coins via GiftTransactionService
    final transactionService = GiftTransactionService();
    final success = await transactionService.purchaseTheme(
      userId: userId,
      themeId: themeId,
      price: price,
    );

    if (!success) return false;

    // Add to owned themes
    _ownedThemes[userId] ??= {};
    _ownedThemes[userId]!.add(themeId);

    LogManager.debug('Theme purchased: $themeId by $userId');
    notifyListeners();

    return true;
  }

  Future<bool> applyTheme(String userId, String themeId) async {
    // Check if owned
    if (!ownsTheme(userId, themeId)) {
      LogManager.debug('Theme not owned');
      return false;
    }

    _activeThemes[userId] = themeId;

    LogManager.debug('Theme applied: $themeId for $userId');
    _broadcastThemeUpdate(userId);
    notifyListeners();

    return true;
  }

  bool ownsTheme(String userId, String themeId) {
    return _ownedThemes[userId]?.contains(themeId) ?? false;
  }

  String getActiveTheme(String userId) {
    return _activeThemes[userId] ?? 'default';
  }

  Set<String> getOwnedThemes(String userId) {
    return _ownedThemes[userId] ?? {};
  }

  // ============ Sticker Pack Management ============

  Future<bool> purchaseStickerPack(
      String userId, String packId, int price) async {
    // Check if already owned
    if (ownsStickerPack(userId, packId)) {
      LogManager.debug('Sticker pack already owned');
      return false;
    }

    // Deduct coins
    final transactionService = GiftTransactionService();
    final success = await transactionService.purchaseStickerPack(
      userId: userId,
      packId: packId,
      price: price,
    );

    if (!success) return false;

    // Add to owned packs
    _ownedStickerPacks[userId] ??= {};
    _ownedStickerPacks[userId]!.add(packId);

    LogManager.debug('Sticker pack purchased: $packId by $userId');
    _broadcastStickerUpdate(userId);
    notifyListeners();

    return true;
  }

  bool ownsStickerPack(String userId, String packId) {
    return _ownedStickerPacks[userId]?.contains(packId) ?? false;
  }

  Set<String> getOwnedStickerPacks(String userId) {
    return _ownedStickerPacks[userId] ?? {};
  }

  List<String> getAvailableStickers(String userId) {
    final ownedPacks = getOwnedStickerPacks(userId);
    final stickers = <String>[];

    // Map pack IDs to their stickers (simplified - in real app would be more complex)
    final packStickers = {
      'emoji_basics': ['😀', '😂', '🥰', '😎', '🤔', '👍', '❤️', '🎉'],
      'gaming': ['🎮', '🕹️', '🏆', '⭐', '💎', '🚀', '⚡', '🔥'],
      'reactions': ['😱', '🤯', '😍', '🤩', '😤', '💪', '👏', '🙌'],
      'animals': ['🐶', '🐱', '🐼', '🦊', '🐨', '🐰', '🦁', '🐯'],
      'food': ['🍕', '🍔', '🍟', '🌮', '🍣', '🍰', '🍦', '☕'],
      'premium_animated': ['✨', '💫', '⚡', '🌟', '💥', '🎊', '🎆', '🌈'],
    };

    for (final packId in ownedPacks) {
      stickers.addAll(packStickers[packId] ?? []);
    }

    return stickers;
  }

  // ============ User Preferences ============

  Future<void> setPreference(String userId, String key, dynamic value) async {
    _userPreferences[userId] ??= {};
    _userPreferences[userId]![key] = value;

    LogManager.debug('Preference set for $userId: $key = $value');
    notifyListeners();
  }

  dynamic getPreference(String userId, String key, {dynamic defaultValue}) {
    return _userPreferences[userId]?[key] ?? defaultValue;
  }

  Map<String, dynamic> getAllPreferences(String userId) {
    return Map.from(_userPreferences[userId] ?? {});
  }

  // Common preferences
  Future<void> setChatBubbleStyle(String userId, String style) async {
    await setPreference(userId, 'chatBubbleStyle', style);
  }

  String getChatBubbleStyle(String userId) {
    return getPreference(userId, 'chatBubbleStyle', defaultValue: 'rounded');
  }

  Future<void> setFontSize(String userId, double size) async {
    await setPreference(userId, 'fontSize', size);
  }

  double getFontSize(String userId) {
    return getPreference(userId, 'fontSize', defaultValue: 14.0);
  }

  Future<void> setNotificationSound(String userId, bool enabled) async {
    await setPreference(userId, 'notificationSound', enabled);
  }

  bool getNotificationSound(String userId) {
    return getPreference(userId, 'notificationSound', defaultValue: true);
  }

  // ============ Streams ============

  Stream<String> watchActiveTheme(String userId) {
    _themeStreams[userId] ??= StreamController<String>.broadcast();

    Future.delayed(Duration.zero, () {
      _broadcastThemeUpdate(userId);
    });

    return _themeStreams[userId]!.stream;
  }

  Stream<Set<String>> watchOwnedStickers(String userId) {
    _stickerStreams[userId] ??= StreamController<Set<String>>.broadcast();

    Future.delayed(Duration.zero, () {
      _broadcastStickerUpdate(userId);
    });

    return _stickerStreams[userId]!.stream;
  }

  void _broadcastThemeUpdate(String userId) {
    final controller = _themeStreams[userId];
    if (controller != null && !controller.isClosed) {
      controller.add(getActiveTheme(userId));
    }
  }

  void _broadcastStickerUpdate(String userId) {
    final controller = _stickerStreams[userId];
    if (controller != null && !controller.isClosed) {
      controller.add(getOwnedStickerPacks(userId));
    }
  }

  // ============ Default Items ============

  void _loadDefaultItems() {
    // Give default theme and basic stickers to all users
    const defaultUsers = ['current_user', 'user_1', 'user_2'];

    for (final userId in defaultUsers) {
      _ownedThemes[userId] = {'default'};
      _activeThemes[userId] = 'default';
      _ownedStickerPacks[userId] = {'emoji_basics'};
    }
  }

  // ============ Analytics ============

  Map<String, dynamic> getCustomizationAnalytics(String userId) {
    return {
      'ownedThemes': getOwnedThemes(userId).length,
      'activeTheme': getActiveTheme(userId),
      'ownedStickerPacks': getOwnedStickerPacks(userId).length,
      'availableStickers': getAvailableStickers(userId).length,
      'preferences': getAllPreferences(userId).length,
    };
  }

  // ============ Synchronization ============

  Future<void> syncCustomizations(String userId) async {
    // In a real app, this would sync with backend
    LogManager.debug('Syncing customizations for $userId');
    await Future.delayed(const Duration(milliseconds: 500));
    notifyListeners();
  }

  Future<Map<String, dynamic>> exportCustomizations(String userId) async {
    return {
      'themes': {
        'owned': getOwnedThemes(userId).toList(),
        'active': getActiveTheme(userId),
      },
      'stickers': {
        'owned': getOwnedStickerPacks(userId).toList(),
      },
      'preferences': getAllPreferences(userId),
    };
  }

  Future<bool> importCustomizations(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      // Import themes
      final themes = data['themes'] as Map<String, dynamic>?;
      if (themes != null) {
        final owned = (themes['owned'] as List?)?.cast<String>();
        if (owned != null) {
          _ownedThemes[userId] = owned.toSet();
        }
        final active = themes['active'] as String?;
        if (active != null) {
          _activeThemes[userId] = active;
        }
      }

      // Import stickers
      final stickers = data['stickers'] as Map<String, dynamic>?;
      if (stickers != null) {
        final owned = (stickers['owned'] as List?)?.cast<String>();
        if (owned != null) {
          _ownedStickerPacks[userId] = owned.toSet();
        }
      }

      // Import preferences
      final prefs = data['preferences'] as Map<String, dynamic>?;
      if (prefs != null) {
        _userPreferences[userId] = prefs;
      }

      LogManager.debug('Customizations imported for $userId');
      notifyListeners();
      return true;
    } catch (e) {
      LogManager.debug('Failed to import customizations: $e');
      return false;
    }
  }
}
