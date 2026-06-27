# LEADERBOARD WEBSOCKET - WHAT YOU NEED TO ADD

## ✅ YOUR SERVICE IS 95% COMPLETE!

You're missing just **3 methods** in LeaderboardDataService. Here's exactly what to add:

---

## 📁 STEP 1: Update LeaderboardDataService (5 minutes)

### Location: `lib/core/services/leaderboard_data_service.dart`

---

### ADD #1: After `_handlePlayerPassed` method (around line 125)

```dart
  // ✅ ADD THIS - Get current leaderboard
  List<LeaderboardEntry> get currentLeaderboard => _currentLeaderboard;

  // ✅ ADD THIS - Subscribe to leaderboard updates
  void subscribe({
    String type = 'global',
    int? tier,
    String? category,
  }) {
    if (_useWebSocket && _wsAdapter != null) {
      _wsAdapter!.subscribe(type: type, tier: tier, category: category);
    }
  }

  // ✅ ADD THIS - Unsubscribe from leaderboard
  void unsubscribe() {
    if (_useWebSocket && _wsAdapter != null) {
      _wsAdapter!.unsubscribe();
    }
  }
```

---

### UPDATE #2: Change existing `dispose()` method (at end of file, line ~565)

**FIND THIS (current code):**
```dart
  /// Dispose method to clean up resources
  void dispose() {
    _isRefreshing = false;
    _lastRefreshTime = null;
  }
```

**REPLACE WITH:**
```dart
  /// Dispose method to clean up resources
  @override
  void dispose() {
    _wsAdapter?.dispose(); // ✅ ADD THIS LINE
    _isRefreshing = false;
    _lastRefreshTime = null;
    super.dispose(); // ✅ ADD THIS LINE
  }
```

---

## ✅ THAT'S IT FOR THE SERVICE!

Just 3 additions:
1. `currentLeaderboard` getter
2. `subscribe()` method
3. `unsubscribe()` method
4. Update `dispose()` to clean up WebSocket

Total time: **5 minutes** 🎯

---

## 📁 STEP 2: Update LeaderboardScreen

Your screen is **beautiful** but it doesn't show leaderboard entries yet. I'll add that without breaking your existing tier/mission/seasonal layout.

**See:** `leaderboard_screen_UPDATED.dart` for complete code

**What I added:**
- ✅ WebSocket initialization in `initState()`
- ✅ WebSocket cleanup in `dispose()`
- ✅ Leaderboard entries section (between tier header and missions)
- ✅ Real-time rank updates
- ✅ Animated rank changes
- ✅ LIVE indicator in app bar
- ✅ Top 10 players display

**What I kept:**
- ✅ Your tier progression widget (unchanged)
- ✅ Your mission panel (unchanged)
- ✅ Your seasonal events (unchanged)
- ✅ Your beautiful animations (unchanged)
- ✅ All your styling (unchanged)

---

## 🎯 KEY DIFFERENCES FROM MY EXAMPLE

My generic example had these parameters you don't have:

**❌ NOT NEEDED (from example):**
```dart
final serviceManager = ref.read(serviceManagerProvider);
```

**✅ YOUR ACTUAL CODE (what you use):**
```dart
final serviceManager = ref.read(serviceManagerProvider);
```

**You already have serviceManagerProvider!** ✅ My example was generic - yours is correct.

---

## ⏱️ IMPLEMENTATION TIME

**Step 1:** Add 3 methods to service (5 min)  
**Step 2:** Replace LeaderboardScreen (2 min)  
**Step 3:** Test (5 min)

**Total:** 12 minutes! 🚀

---

## ✅ VERIFICATION

After implementation, you should see:

**Console logs:**
```
[Leaderboard] Using WebSocket mode
[LeaderboardWS] Initialized
[LeaderboardWS] Subscribed to global leaderboard
[Leaderboard] Initialized with 100 entries
```

**On screen:**
- ✅ "LIVE" indicator in app bar (red badge)
- ✅ Leaderboard entries showing (top 10)
- ✅ Ranks with colors (gold/silver/bronze)
- ✅ Player names and scores
- ✅ Tier progression (your existing widget)
- ✅ Missions panel (your existing widget)
- ✅ Seasonal events (your existing widget)

---

## 📊 LAYOUT

Your screen will now have this order:

1. **App Bar** (with LIVE indicator)
2. **Tier Progression** (your existing widget)
3. **Leaderboard Entries** (NEW - top 10 players)
4. **Mission Panel** (your existing widget)
5. **Seasonal Events** (your existing widget)

Everything flows naturally! 🎨

---

## 🎯 NEXT STEPS

1. Open `leaderboard_data_service.dart`
2. Add the 3 methods (5 min)
3. Update `dispose()` method (1 min)
4. Copy `leaderboard_screen_UPDATED.dart` → replace your current screen
5. Run and test!

**Ready to implement?** Let me know if you have questions! 💪
