# TRIVIA TYCOON - GRACEFUL SHUTDOWN INSTALLATION

Blake, here's your **exact step-by-step guide** for integrating graceful shutdown into your app.

---

## 📦 WHAT YOU'RE INSTALLING (2 New Files + 3 Updates)

### New Files (Add These):
1. **app_lifecycle_manager.dart** - Monitors app lifecycle (close, crash, background)
2. **state_persistence_service.dart** - Saves/loads data using Hive

### Updated Files (Modify These):
3. **app_init.dart** - Add lifecycle & persistence initialization
4. **main.dart** - Add crash recovery dialog
5. **app_launcher.dart** - Add cleanup on dispose

---

## 🚀 INSTALLATION (15 Minutes)

### STEP 1: Add New Service Files (2 min)

```bash
# Create services directory if needed
mkdir -p lib/core/services

# Copy the two service files
cp app_lifecycle_manager.dart lib/core/services/
cp state_persistence_service_HIVE.dart lib/core/services/state_persistence_service.dart
```

**Files to copy:**
- `app_lifecycle_manager.dart` (from previous delivery)
- `state_persistence_service_HIVE.dart` → rename to `state_persistence_service.dart`

---

### STEP 2: Update app_init.dart (5 min)

Open `lib/core/bootstrap/app_init.dart` and make these changes:

#### Change 1: Add Imports (Line ~22)

**After your existing imports, add:**
```dart
import '../services/app_lifecycle_manager.dart';
import '../services/state_persistence_service.dart';
```

#### Change 2: Add Static Instances (Line ~24, after _tokenStore)

**Add these 3 variables:**
```dart
  static AuthTokenStore? _tokenStore;
  static AuthTokenStore? get tokenStore => _tokenStore;

  // ✅ ADD THESE
  static AppLifecycleManager? _lifecycleManager;
  static AppLifecycleManager? get lifecycleManager => _lifecycleManager;
  
  static StatePersistenceService? _persistenceService;
  static StatePersistenceService? get persistenceService => _persistenceService;
  
  static ServiceManager? _serviceManager;
```

#### Change 3: Initialize Persistence (Line ~48, after opening boxes)

**After the Hive box initialization, add:**
```dart
    final authTokenBox = await Hive.openBox('auth_tokens');
    final settingsBox = await Hive.openBox('settings');
    final secretsBox = await Hive.openBox('secrets');

    // ✅ ADD THIS
    _persistenceService = StatePersistenceService();
    await _persistenceService!.initialize();
    debugPrint('✅ StatePersistenceService ready');
```

#### Change 4: Initialize Lifecycle Manager (Line ~81, after ServiceManager)

**After `final serviceManager = await ServiceManager.initialize();`, add:**
```dart
    final serviceManager = await ServiceManager.initialize();
    _serviceManager = serviceManager; // ✅ ADD THIS

    // ✅ ADD THIS ENTIRE BLOCK
    _lifecycleManager = AppLifecycleManager(
      onAppPaused: () => debugPrint('[Lifecycle] 📱 PAUSED'),
      onAppResumed: () => debugPrint('[Lifecycle] 📱 RESUMED'),
      onAppDetached: () => debugPrint('[Lifecycle] 📱 DETACHED'),
      onAppInactive: () => debugPrint('[Lifecycle] 📱 INACTIVE'),
      onSaveState: () async => await _saveAppState(),
      onClearTempData: () async => await _persistenceService?.clearTemporaryData(),
    );
    _lifecycleManager!.initialize();
    debugPrint('✅ AppLifecycleManager initialized');
```

#### Change 5: Add Save Methods (At the end of class, after _initializeReferralStorage)

**Copy all these methods from `APP_INIT_CHANGES.md` section 5:**
- `_saveAppState()`
- `_getCurrentGameState()`
- `_getCurrentUserSession()`
- `_getCurrentWebSocketState()`
- `_getPendingActions()`
- `forceSave()`
- `dispose()`

**See `APP_INIT_CHANGES.md` for the complete code (120 lines)**

---

### STEP 3: Update main.dart (5 min)

Open `lib/main.dart` and make these changes:

#### Change 1: Add State Variable (Line ~93)

**Add one line:**
```dart
  bool _splashFinished = false;
  Object? _error;
  bool _recoveryChecked = false; // ✅ ADD THIS
```

#### Change 2: Update _onSplashFinished (Line ~117)

**Replace existing method:**
```dart
  void _onSplashFinished() {
    setState(() {
      _splashFinished = true;
    });
    _checkForCrashRecovery(); // ✅ ADD THIS LINE
  }
```

#### Change 3: Add Recovery Methods (After _onSplashFinished)

**Add these 3 methods from `MAIN_CHANGES.md` section 3:**
- `_checkForCrashRecovery()`
- `_showCrashRecoveryDialog()`
- `_restoreCrashedSession()`

**See `MAIN_CHANGES.md` for the complete code (150 lines)**

#### Change 4: Add Recovery Check (In _buildContent, Line ~124)

**After the splash check, add:**
```dart
    if (!_splashFinished) {
      return SimpleSplashScreen(onDone: _onSplashFinished);
    }

    // ✅ ADD THIS ENTIRE BLOCK
    if (!_recoveryChecked) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppLogo(size: 120, animate: true),
              const SizedBox(height: 32),
              const CircularProgressIndicator(color: Color(0xFF6366F1)),
              const SizedBox(height: 16),
              const Text('Checking for saved progress...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }
```

---

### STEP 4: Update app_launcher.dart (1 min)

Open `lib/core/bootstrap/app_launcher.dart` and make this change:

#### Only Change: Update dispose (Line ~41)

**Add one line:**
```dart
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppInit.dispose(); // ✅ ADD THIS LINE
    super.dispose();
  }
```

**That's it! Your existing lifecycle handling is perfect!**

---

### STEP 5: Test (2 min)

```bash
flutter clean
flutter pub get
flutter run
```

---

## ✅ VERIFICATION CHECKLIST

After installation, verify:

- [ ] App compiles without errors
- [ ] App runs and shows splash screen
- [ ] After splash, shows "Checking for saved progress..."
- [ ] App loads normally (no recovery dialog on first run)
- [ ] Console shows:
  ```
  ✅ StatePersistenceService ready
  ✅ AppLifecycleManager initialized
  ```

---

## 🧪 TESTING THE SYSTEM

### Test 1: Normal Close (Should NOT show dialog)
```
1. Run app
2. Navigate around normally
3. Close app with back button
4. Reopen app
5. ✅ Expected: No recovery dialog
```

### Test 2: Crash Recovery (Should show dialog)
```
1. Run app
2. Swipe app away in task manager (force kill)
3. Reopen app
4. ✅ Expected: "Welcome Back!" dialog appears
5. Tap "Restore" or "Start Fresh"
```

### Test 3: Auto-Save (Check logs)
```
1. Run app
2. Let it sit for 2 minutes
3. Check console logs
4. ✅ Expected: See "[Lifecycle] Auto-save triggered" every 30s
```

### Test 4: Background/Foreground
```
1. Run app
2. Press home button (background)
3. Console shows: "[Lifecycle] 📱 PAUSED"
4. Return to app
5. Console shows: "[Lifecycle] 📱 RESUMED"
6. ✅ Expected: WebSocket reconnects, no data loss
```

---

## 🎯 CUSTOMIZATION (Do This After Testing)

### Customize Game State Saving

In `app_init.dart`, update `_getCurrentGameState()`:

```dart
static Future<Map<String, dynamic>?> _getCurrentGameState() async {
  try {
    // ✅ REPLACE with your actual game state
    final quizBox = await Hive.openBox('current_quiz');
    if (quizBox.isEmpty) return null;
    
    return {
      'quiz_id': quizBox.get('quiz_id'),
      'current_question': quizBox.get('current_question'),
      'score': quizBox.get('score'),
      'lives': quizBox.get('lives'),
      'power_ups': quizBox.get('power_ups'),
      'answers': quizBox.get('answers'),
    };
  } catch (e) {
    debugPrint('[AppInit] ⚠️ Get game state error: $e');
    return null;
  }
}
```

### Customize Game State Restoration

In `main.dart`, update `_restoreCrashedSession()`:

```dart
Future<void> _restoreCrashedSession(Map<String, dynamic> summary) async {
  try {
    final persistenceService = AppInit.persistenceService;
    if (persistenceService == null) return;

    final gameState = await persistenceService.getGameState();
    
    // ✅ REPLACE with your actual restore logic
    if (gameState != null) {
      final quizBox = await Hive.openBox('current_quiz');
      await quizBox.put('quiz_id', gameState['quiz_id']);
      await quizBox.put('current_question', gameState['current_question']);
      await quizBox.put('score', gameState['score']);
      await quizBox.put('lives', gameState['lives']);
      await quizBox.put('power_ups', gameState['power_ups']);
      await quizBox.put('answers', gameState['answers']);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Game progress restored!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    debugPrint('[Recovery] ❌ Restore failed: $e');
  }
}
```

---

## 📊 WHAT GETS SAVED

Your app now automatically saves:

### Every 30 Seconds:
- Current quiz state (if playing)
- User session info
- WebSocket connection status
- Pending actions (failed requests)

### On App Close/Crash:
- Emergency save before shutdown
- Sets crash flag for recovery

### On Background:
- Full state save
- WebSocket disconnects

### On Foreground:
- WebSocket reconnects
- State preserved

---

## 💡 USAGE EXAMPLES

### Force Save Before Critical Action

```dart
// In your quiz submit screen
await AppInit.forceSave();
await submitFinalScore();
```

### Queue Failed Request for Retry

```dart
// When API call fails
try {
  await api.submitScore(score);
} catch (e) {
  final pendingBox = await Hive.openBox('pending_requests');
  await pendingBox.add({
    'type': 'submit_score',
    'data': {'score': score, 'quiz_id': quizId},
    'timestamp': DateTime.now().toIso8601String(),
  });
  // Will be retried on next launch
}
```

---

## 🐛 TROUBLESHOOTING

### Issue: Compile errors about missing classes

**Solution:** Make sure you copied both service files:
```bash
ls lib/core/services/app_lifecycle_manager.dart
ls lib/core/services/state_persistence_service.dart
```

### Issue: Recovery dialog never shows

**Solution:** The app is closing normally. To test crash recovery:
1. Force kill app (swipe away in task manager)
2. Reopen - dialog should appear

### Issue: "Checking for saved progress..." shows forever

**Solution:** Check console for errors. The `_checkForCrashRecovery()` method may have thrown an exception.

### Issue: Auto-save not logging

**Solution:** Check if lifecycle manager initialized:
```
Console should show: "✅ AppLifecycleManager initialized"
```

---

## 📋 FILES REFERENCE

All the complete code is in these files:

1. **APP_INIT_CHANGES.md** - All changes for app_init.dart
2. **MAIN_CHANGES.md** - All changes for main.dart  
3. **APP_LAUNCHER_CHANGES.md** - All changes for app_launcher.dart
4. **app_lifecycle_manager.dart** - New service file
5. **state_persistence_service_HIVE.dart** - New service file

---

## ✅ SUMMARY

**Total Changes:**
- ✅ 2 new files added (~400 lines total)
- ✅ 3 files updated (~280 lines added)
- ✅ 0 breaking changes
- ✅ 100% backward compatible

**Time Required:**
- Installation: 15 minutes
- Testing: 5 minutes
- Customization: 10 minutes
- **Total: 30 minutes**

**Benefits:**
- ✅ Never lose user progress
- ✅ Crash recovery with dialog
- ✅ Auto-save every 30s
- ✅ Queue failed requests
- ✅ Clean shutdown

---

## 🚀 READY TO GO!

Blake, follow the 5 steps above and you'll have bulletproof state management! 

Questions? Check the individual change files for complete code listings! 💪
