# app_init.dart - EXACT CHANGES

## WHAT TO ADD

### 1. Add Imports (at top, after existing imports)

```dart
// ✅ ADD THESE TWO LINES after your existing imports
import '../services/app_lifecycle_manager.dart';
import '../services/state_persistence_service.dart';
```

### 2. Add Static Instances (after line 21, where you have _tokenStore)

```dart
  // ✅ Store tokenStore for WebSocket
  static AuthTokenStore? _tokenStore;
  static AuthTokenStore? get tokenStore => _tokenStore;

  // ✅ ADD THESE - Graceful shutdown services
  static AppLifecycleManager? _lifecycleManager;
  static AppLifecycleManager? get lifecycleManager => _lifecycleManager;
  
  static StatePersistenceService? _persistenceService;
  static StatePersistenceService? get persistenceService => _persistenceService;
  
  static ServiceManager? _serviceManager;
```

### 3. Initialize Persistence Service (in initialize(), after line 47)

```dart
    // Open critical boxes required for theme/auth immediately
    final authTokenBox = await Hive.openBox('auth_tokens');
    final settingsBox = await Hive.openBox('settings');
    final secretsBox = await Hive.openBox('secrets');

    // ✅ ADD THIS - Initialize persistence service early
    _persistenceService = StatePersistenceService();
    await _persistenceService!.initialize();
    debugPrint('✅ StatePersistenceService ready');
```

### 4. Initialize Lifecycle Manager (in initialize(), after ServiceManager, around line 80)

```dart
    // 3. Service Manager & Core Logic
    final serviceManager = await ServiceManager.initialize();
    _serviceManager = serviceManager; // ✅ ADD THIS - Store for lifecycle callbacks

    // ✅ ADD THIS ENTIRE BLOCK - Initialize lifecycle manager
    _lifecycleManager = AppLifecycleManager(
      onAppPaused: () {
        debugPrint('[Lifecycle] 📱 App PAUSED');
      },
      onAppResumed: () {
        debugPrint('[Lifecycle] 📱 App RESUMED');
      },
      onAppDetached: () {
        debugPrint('[Lifecycle] 📱 App DETACHED');
      },
      onAppInactive: () {
        debugPrint('[Lifecycle] 📱 App INACTIVE');
      },
      onSaveState: () async {
        await _saveAppState();
      },
      onClearTempData: () async {
        await _persistenceService?.clearTemporaryData();
      },
    );
    _lifecycleManager!.initialize();
    debugPrint('✅ AppLifecycleManager initialized');
```

### 5. Add Save Methods (at the end of the class, after _initializeReferralStorage)

```dart
  static Future<void> _initializeReferralStorage() async {
    final referralStorage = ReferralStorageService();
    await referralStorage.initialize();
  }

  // ✅ ADD ALL THESE NEW METHODS

  /// Save all app state
  static Future<void> _saveAppState() async {
    if (_serviceManager == null || _persistenceService == null) {
      debugPrint('[AppInit] ⚠️ Services not ready, skipping save');
      return;
    }

    try {
      // 1. Gather game state (if in active game)
      final gameState = await _getCurrentGameState();
      
      // 2. Gather user session
      final userSession = await _getCurrentUserSession();
      
      // 3. Gather WebSocket state
      final wsState = await _getCurrentWebSocketState();
      
      // 4. Gather pending actions
      final pendingActions = await _getPendingActions();
      
      // 5. Save everything
      await _persistenceService!.saveAll(
        gameState: gameState,
        userSession: userSession,
        wsState: wsState,
        pendingActions: pendingActions,
      );
      
      debugPrint('[AppInit] ✅ App state saved');
    } catch (e, stack) {
      debugPrint('[AppInit] ❌ Save failed: $e');
      debugPrint('[AppInit] Stack: $stack');
    }
  }

  /// Get current game state (customize for your game)
  static Future<Map<String, dynamic>?> _getCurrentGameState() async {
    try {
      // TODO: Replace with your actual game state
      // Example if you store quiz state in Hive:
      // final quizBox = await Hive.openBox('current_quiz');
      // if (quizBox.isEmpty) return null;
      // return {
      //   'quiz_id': quizBox.get('quiz_id'),
      //   'current_question': quizBox.get('current_question'),
      //   'score': quizBox.get('score'),
      //   'lives': quizBox.get('lives'),
      // };
      
      return null; // No active game
    } catch (e) {
      debugPrint('[AppInit] ⚠️ Get game state error: $e');
      return null;
    }
  }

  /// Get current user session
  static Future<Map<String, dynamic>?> _getCurrentUserSession() async {
    try {
      if (_serviceManager == null) return null;
      
      final isLoggedIn = await _serviceManager!.authService.isLoggedIn();
      if (!isLoggedIn) return null;
      
      final session = _tokenStore?.load();
      final rawProfile = await _serviceManager!.playerProfileService.getProfile();
      final profile = rawProfile != null ? Map<String, dynamic>.from(rawProfile as Map) : {};
      
      return {
        'is_logged_in': isLoggedIn,
        'user_id': profile['id'],
        'user_name': profile['name'],
        'has_tokens': session?.hasTokens ?? false,
        'session_start': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('[AppInit] ⚠️ Get user session error: $e');
      return null;
    }
  }

  /// Get WebSocket state
  static Future<Map<String, dynamic>?> _getCurrentWebSocketState() async {
    try {
      if (_wsClient == null) return null;
      
      return {
        'connected': _wsConnected,
        'url': EnvConfig.apiWsBaseUrl,
        'last_connection': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('[AppInit] ⚠️ Get WebSocket state error: $e');
      return null;
    }
  }

  /// Get pending actions (failed requests)
  static Future<List<Map<String, dynamic>>> _getPendingActions() async {
    try {
      // TODO: Get from your pending requests queue
      // Example:
      // final pendingBox = await Hive.openBox('pending_requests');
      // return pendingBox.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      
      return [];
    } catch (e) {
      debugPrint('[AppInit] ⚠️ Get pending actions error: $e');
      return [];
    }
  }

  /// Force save (call before critical operations)
  static Future<void> forceSave() async {
    if (_lifecycleManager != null) {
      await _lifecycleManager!.forceSave();
    }
  }

  /// Cleanup on app shutdown
  static Future<void> dispose() async {
    try {
      debugPrint('[AppInit] 👋 Disposing...');
      await disconnectWebSocket();
      await _saveAppState();
      _lifecycleManager?.dispose();
      debugPrint('[AppInit] ✅ Cleanup complete');
    } catch (e) {
      debugPrint('[AppInit] ❌ Dispose error: $e');
    }
  }
}
```

---

## SUMMARY OF CHANGES

1. **2 new imports** - lifecycle manager and persistence service
2. **3 new static variables** - for lifecycle, persistence, and service manager
3. **1 initialization block** - persistence service (3 lines)
4. **1 initialization block** - lifecycle manager (15 lines)
5. **7 new methods** - save logic, getters, force save, dispose

**Total lines added:** ~120 lines
**Files modified:** 0 (only additions)
**Breaking changes:** 0 (100% backward compatible)
