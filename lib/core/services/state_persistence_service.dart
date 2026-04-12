import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

/// Manages persistent state across app sessions using Hive
///
/// Saves critical data when app closes or crashes:
/// - Game progress (quiz state, score, answers)
/// - User session (auth, preferences)
/// - Pending actions (unsent scores, messages, etc.)
/// - WebSocket state
class StatePersistenceService {
  static const String _boxName = 'app_persistence';

  // Keys
  static const String _lastSaveKey = 'last_save_timestamp';
  static const String _crashRecoveryKey = 'crash_recovery_flag';
  static const String _pendingActionsKey = 'pending_actions';
  static const String _gameStateKey = 'game_state';
  static const String _userSessionKey = 'user_session';
  static const String _wsStateKey = 'ws_state';

  late Box _box;
  bool _isInitialized = false;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Open dedicated persistence box
      _box = await Hive.openBox(_boxName);
      _isInitialized = true;

      LogManager.debug('[StatePersistence] ✅ Initialized');

      // Check if last session crashed
      await _checkForCrash();
    } catch (e) {
      LogManager.debug('[StatePersistence] ❌ Init error: $e');
    }
  }

  /// Save all critical state
  Future<void> saveAll({
    Map<String, dynamic>? gameState,
    Map<String, dynamic>? userSession,
    Map<String, dynamic>? wsState,
    List<Map<String, dynamic>>? pendingActions,
  }) async {
    if (!_isInitialized) {
      LogManager.debug('[StatePersistence] ⚠️ Not initialized, skipping save');
      return;
    }

    try {
      final startTime = DateTime.now();

      // Save game state (current quiz, score, etc.)
      if (gameState != null && gameState.isNotEmpty) {
        await _box.put(_gameStateKey, gameState);
        LogManager.debug('[StatePersistence] 💾 Game state saved');
      }

      // Save user session (auth tokens, preferences)
      if (userSession != null && userSession.isNotEmpty) {
        await _box.put(_userSessionKey, userSession);
        LogManager.debug('[StatePersistence] 💾 User session saved');
      }

      // Save WebSocket state
      if (wsState != null && wsState.isNotEmpty) {
        await _box.put(_wsStateKey, wsState);
        LogManager.debug('[StatePersistence] 💾 WebSocket state saved');
      }

      // Save pending actions (unsent data)
      if (pendingActions != null && pendingActions.isNotEmpty) {
        await _box.put(_pendingActionsKey, pendingActions);
        LogManager.debug('[StatePersistence] 💾 Saved ${pendingActions.length} pending actions');
      }

      // Mark successful save (clear crash flag)
      await _markSaveComplete();

      final duration = DateTime.now().difference(startTime);
      LogManager.debug('[StatePersistence] ✅ Saved all state in ${duration.inMilliseconds}ms');
    } catch (e, stack) {
      LogManager.debug('[StatePersistence] ❌ Save failed: $e');
      LogManager.debug('[StatePersistence] Stack: $stack');
    }
  }

  /// Mark save as complete (used for crash detection)
  Future<void> _markSaveComplete() async {
    final timestamp = DateTime.now().toIso8601String();
    await _box.put(_lastSaveKey, timestamp);
    await _box.put(_crashRecoveryKey, false); // Normal save, no crash
  }

  /// Check if app crashed in last session
  Future<void> _checkForCrash() async {
    try {
      final didCrash = _box.get(_crashRecoveryKey, defaultValue: false) as bool;

      if (didCrash) {
        LogManager.debug('[StatePersistence] ⚠️ CRASH DETECTED - Previous session crashed!');
        LogManager.debug('[StatePersistence] 🔄 Recovery data available');
      } else {
        LogManager.debug('[StatePersistence] ✅ Previous session closed normally');
      }

      // Mark this session as potentially crashed (cleared on normal save)
      await _box.put(_crashRecoveryKey, true);
    } catch (e) {
      LogManager.debug('[StatePersistence] ❌ Crash check failed: $e');
    }
  }

  /// Get saved game state
  Future<Map<String, dynamic>?> getGameState() async {
    try {
      final state = _box.get(_gameStateKey);
      if (state == null) return null;

      // Convert to Map<String, dynamic> safely
      return Map<String, dynamic>.from(state as Map);
    } catch (e) {
      LogManager.debug('[StatePersistence] ❌ Get game state failed: $e');
      return null;
    }
  }

  /// Get saved user session
  Future<Map<String, dynamic>?> getUserSession() async {
    try {
      final session = _box.get(_userSessionKey);
      if (session == null) return null;

      return Map<String, dynamic>.from(session as Map);
    } catch (e) {
      LogManager.debug('[StatePersistence] ❌ Get user session failed: $e');
      return null;
    }
  }

  /// Get saved WebSocket state
  Future<Map<String, dynamic>?> getWebSocketState() async {
    try {
      final state = _box.get(_wsStateKey);
      if (state == null) return null;

      return Map<String, dynamic>.from(state as Map);
    } catch (e) {
      LogManager.debug('[StatePersistence] ❌ Get WebSocket state failed: $e');
      return null;
    }
  }

  /// Get pending actions
  Future<List<Map<String, dynamic>>> getPendingActions() async {
    try {
      final actions = _box.get(_pendingActionsKey);
      if (actions == null) return [];

      // Convert to List<Map<String, dynamic>> safely
      return (actions as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (e) {
      LogManager.debug('[StatePersistence] ❌ Get pending actions failed: $e');
      return [];
    }
  }

  /// Clear all pending actions (after successful retry)
  Future<void> clearPendingActions() async {
    try {
      await _box.delete(_pendingActionsKey);
      LogManager.debug('[StatePersistence] 🗑️ Cleared pending actions');
    } catch (e) {
      LogManager.debug('[StatePersistence] ❌ Clear pending actions failed: $e');
    }
  }

  /// Clear temporary data (call on clean shutdown)
  Future<void> clearTemporaryData() async {
    try {
      // Clear game state (session ended)
      await _box.delete(_gameStateKey);

      // Keep user session and pending actions
      // Only clear game-specific data

      LogManager.debug('[StatePersistence] 🗑️ Cleared temporary data');
    } catch (e) {
      LogManager.debug('[StatePersistence] ❌ Clear temp data failed: $e');
    }
  }

  /// Clear ALL data (for logout/fresh start)
  Future<void> clearAll() async {
    try {
      await _box.clear();
      LogManager.debug('[StatePersistence] 🗑️ Cleared all persistence data');
    } catch (e) {
      LogManager.debug('[StatePersistence] ❌ Clear all failed: $e');
    }
  }

  /// Get time of last save
  DateTime? getLastSaveTime() {
    try {
      final timestamp = _box.get(_lastSaveKey) as String?;
      if (timestamp == null) return null;
      return DateTime.parse(timestamp);
    } catch (e) {
      LogManager.debug('[StatePersistence] ❌ Get last save time failed: $e');
      return null;
    }
  }

  /// Check if there's recoverable data
  Future<bool> hasRecoverableData() async {
    try {
      final didCrash = _box.get(_crashRecoveryKey, defaultValue: false) as bool;
      if (!didCrash) return false;

      final gameState = await getGameState();
      final userSession = await getUserSession();
      final pendingActions = await getPendingActions();

      return gameState != null || userSession != null || pendingActions.isNotEmpty;
    } catch (e) {
      LogManager.debug('[StatePersistence] ❌ Check recoverable data failed: $e');
      return false;
    }
  }

  /// Get recovery summary for display
  Future<Map<String, dynamic>> getRecoverySummary() async {
    try {
      final gameState = await getGameState();
      final userSession = await getUserSession();
      final pendingActions = await getPendingActions();
      final lastSave = getLastSaveTime();

      return {
        'has_game_state': gameState != null,
        'game_state': gameState,
        'has_user_session': userSession != null,
        'user_session': userSession,
        'pending_actions_count': pendingActions.length,
        'pending_actions': pendingActions,
        'last_save': lastSave?.toIso8601String(),
      };
    } catch (e) {
      LogManager.debug('[StatePersistence] ❌ Get recovery summary failed: $e');
      return {};
    }
  }

  /// Dispose (cleanup)
  Future<void> dispose() async {
    try {
      // Hive boxes don't need explicit disposal
      // They're managed by Hive globally
      _isInitialized = false;
      LogManager.debug('[StatePersistence] 👋 Disposed');
    } catch (e) {
      LogManager.debug('[StatePersistence] ❌ Dispose error: $e');
    }
  }

  /// Clears the crash flag after the user accepts recovery so the prompt
  /// does not repeat on the next normal launch.
  Future<void> markRecoveryHandled() async {
    if (!_isInitialized) return;

    try {
      await _markSaveComplete();
      LogManager.debug('[StatePersistence] ✅ Recovery marked handled');
    } catch (e) {
      LogManager.debug('[StatePersistence] ❌ Mark recovery handled failed: $e');
    }
  }
}
