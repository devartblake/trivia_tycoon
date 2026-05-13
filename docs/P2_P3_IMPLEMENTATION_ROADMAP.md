# P2-P3 Implementation Roadmap
## Trivia Tycoon - Advanced Features

---

## 📊 Current Status

_Updated: 2026-05-12 (batch 2) — Branch `claude/fix-hexagon-alignment-CrQVu`_

✅ **P1 Completed:**
- Backend auth integration working
- Role & premium extraction functional
- Metadata persistence implemented
- Connection issues resolved

✅ **P2 Test coverage (Phase 3) — substantially complete:**
- Auth edge cases: offline login, 401 best-effort logout, concurrent refresh, token expiry, OAuth URL, session metadata (`test/core/services/auth_service_test.dart`)
- Widget tests for `DailyBonusScreen` and `ArcadeMissionsScreen` (`test/arcade/screens/arcade_screens_widget_test.dart`)
- Skill tree branch detail expanded: `showPath=0`, step clamping, correct step labels (`test/screens/skills_tree/skill_branch_detail_screen_test.dart`)
- `ArcadeGameShell` widget tests: patternSprint/memoryFlip/quickMathRush mount, `ArcadeRunApi.of()`, difficulty propagation (`test/arcade/screens/arcade_game_shell_test.dart`)
- Crypto wallet UI smoke tests: disabled feature, unlinked/linked, balance, staked units, staking summary, pending withdrawal, empty history (`test/screens/store/crypto_wallet_screen_test.dart`)
- Secure channel replay/sequence/expiry/reinstall/web-fallback tests: 15 tests in 3 groups (`test/core/security/secure_payload_codec_test.dart`)
- Remaining: leaderboard interaction tests (`AnimatedRankBadge`, `EnhancedScoreDisplay`); 40% coverage milestone

✅ **Rewards backend wiring — complete:**
- `lib/game/services/rewards_api_service.dart` — `GET /rewards/daily-config`, `POST /rewards/daily/claim`, `GET /rewards/weekly-streak/{id}`, `POST /rewards/weekly/claim`, `GET /spins/stats/{id}`, `GET /spins/history/{id}`, `GET /rewards/spin-reward-steps`
- `lib/game/providers/reward_backend_providers.dart` — `dailyRewardConfigProvider`, `weeklyStreakProvider`, `weeklyRewardScheduleProvider`, `serverSpinStatisticsProvider`, `spinRewardStepsProvider`, `serverSpinHistoryProvider`
- Frontend screens wired: `reward_screen.dart`, `weekly_rewards_widget.dart`, `spin_earn_screen.dart`, `mission_screen.dart`

✅ **Skill tree hex grid layout — complete:**
- `SkillTreeController._computeLayout()` replaced radial BFS with true axial hex-grid: `master_hub` at `(0,0)`, 12 branch roots at ring-2, tiers extend along branch direction vectors
- `HexMetrics.axialToPixel` converts `(q,r)` to world pixel offsets

---

## 🎯 P2 - High Priority Improvements

### 1. ✅ Metadata Persistence - ALREADY DONE!
**Status:** Complete in `auth_token_store.dart`
- AuthSession has metadata field
- Metadata saved/loaded from Hive
- Role and premium helpers working

**No action needed!**

---

### 2. 🔄 Automatic Token Refresh (30 minutes)

**Priority:** P2 - High  
**Effort:** 30 minutes  
**Status:** Ready to implement

#### What It Does:
- Automatically refreshes expired tokens before requests
- Retries failed requests with new token
- No more "session expired" interruptions

#### Implementation:

**Step 1: Add AuthHttpClient** (5 minutes)
```bash
# Copy the provided file
cp auth_http_client.dart lib/core/services/auth_http_client.dart
```

**Step 2: Update Riverpod Provider** (5 minutes)

Add to `lib/game/providers/riverpod_providers.dart`:
```dart
/// Provides authenticated HTTP client with auto-refresh
final authHttpClientProvider = Provider<AuthHttpClient>((ref) {
  return AuthHttpClient(
    ref.watch(coreAuthServiceProvider),
    ref.watch(authTokenStoreProvider),
    autoRefresh: true,
    onTokenRefreshed: () {
      debugPrint('[AuthHttpClient] Token auto-refreshed');
    },
    onRefreshFailed: (error) {
      debugPrint('[AuthHttpClient] Refresh failed: $error');
      // Could trigger logout or re-login prompt here
    },
  );
});
```

**Step 3: Use in API Calls** (20 minutes)

Replace regular http.Client with AuthHttpClient:

**Before:**
```dart
final response = await http.get(
  Uri.parse('$apiUrl/data'),
  headers: {'Authorization': 'Bearer $token'},
);
```

**After:**
```dart
final client = ref.read(authHttpClientProvider);
final response = await client.get(Uri.parse('$apiUrl/data'));
// Auth header and refresh automatically handled!
```

**Files to Update:**
- `lib/core/services/api_service.dart` - Replace http.Client with AuthHttpClient
- `lib/game/services/*.dart` - Any direct HTTP calls
- `lib/core/networkting/http_client.dart` - If exists

---

### 3. 💬 Better Error Messages (20 minutes)

**Priority:** P2 - High  
**Effort:** 20 minutes  
**Status:** Ready to implement

#### What It Does:
- Converts technical errors to user-friendly messages
- Specific messages for auth operations
- Better UX when things go wrong

#### Implementation:

**Step 1: Add Error Handler** (5 minutes)
```bash
cp auth_error_messages.dart lib/core/services/auth_error_messages.dart
```

**Step 2: Update Login Screen** (10 minutes)

In `lib/screens/login_screen.dart`:

**Before:**
```dart
try {
  await loginManager.login(email, password);
} catch (e) {
  showError('Login failed: $e'); // ❌ Technical message
}
```

**After:**
```dart
try {
  await loginManager.login(email, password);
} catch (e) {
  final message = AuthErrorMessages.getLoginErrorMessage(e);
  showError(message); // ✅ User-friendly message
}
```

**Step 3: Update Signup Screen** (5 minutes)

Similar changes in signup flow:
```dart
catch (e) {
  final message = AuthErrorMessages.getSignupErrorMessage(e);
  showError(message);
}
```

**Files to Update:**
- `lib/screens/login_screen.dart`
- `lib/ui_components/login/cards/login_card.dart`
- `lib/ui_components/login/cards/signup_card.dart`
- `lib/game/providers/auth_providers.dart`

---

## 🎨 P3 - Nice to Have Improvements

### 4. 🧪 Unit Tests ✅ IN PROGRESS

**Priority:** P3 - Medium  
**Effort:** 2-3 hours  
**Status:** Substantial coverage added; 40% milestone in progress

#### Already complete (test files exist):
- `test/core/services/auth_service_test.dart` — login/signup/refresh/logout + edge cases (offline, 401, concurrent, metadata, OAuth URL)
- `test/core/services/presence/rich_presence_service_test.dart` — 12 cases
- `test/game/controllers/skill_tree_controller_test.dart` — unlock/respec/select/BFS/storage restore
- `test/game/services/skill_cooldown_service_test.dart`
- `test/game/providers/crypto_providers_test.dart`
- `test/arcade/screens/arcade_screens_widget_test.dart` — `DailyBonusScreen`, `ArcadeMissionsScreen` widget smoke tests
- `test/arcade/screens/arcade_game_shell_test.dart` — `ArcadeGameShell` mounts correct widget per `ArcadeGameId`, `ArcadeRunApi.of()`, difficulty propagation ✅ NEW
- `test/screens/skills_tree/skill_branch_detail_screen_test.dart` — query hydration, cooldown, showPath, step clamping
- `test/screens/store/crypto_wallet_screen_test.dart` — disabled feature, unlinked/linked wallet, balance/staked units, staking summary, pending withdrawal, empty history ✅ NEW
- `test/core/security/secure_payload_codec_test.dart` — replay/sequence protection, SecureSession expiry/sequence, SecureSessionStore reinstall/web-fallback ✅ NEW (15 tests in 3 new groups)
- `test/widgets/leaderboard_widgets_test.dart` — extended with `AnimatedRankBadge` interaction tests (up/down arrows, no-arrow states, animation) and `EnhancedScoreDisplay` interaction tests (5 performance message tiers, percentage label, XP section, XP animation, category breakdown, power-up section, class level badge) ✅ NEW
- `test/core/manager/login_manager_test.dart` — 16 unit tests: role extraction from `role`/`roles`/`tier` fields, admin role mapping, premium status from `isPremium`/`subscriptionStatus`/`tier`, `getNextRoute()` routing, `isLoggedIn()` state, userId persistence ✅ NEW
- `test/core/services/auth_token_store_test.dart` — `AuthSession` (hasTokens, isExpired, role/roles, isPremium, tier, copyWith, toJson/fromJson) + `AuthTokenStore` (load/save/clear/updateAccessToken/hasTokens/getRole/isPremium) — 30+ tests ✅ NEW
- `test/game/providers/auth_providers_test.dart` — `AuthState.copyWith`, `AuthStateNotifier` (login/signup/logout/setRole/setPremiumStatus/clearError), `isLoggedInSyncProvider`, `profileSelectedProvider` — 20+ tests ✅ NEW
- `test/game/controllers/leaderboard_controller_test.dart` — initial state, setCategory, applySorting, daily/weekly/global filter, score/rank sort, promoteUser, banUser, pause/resume, exportLeaderboardData, isFilterActive, getLeaderboardStats — 25+ tests ✅ NEW
- `test/game/controllers/question_controller_test.dart` — `QuestionState.initial()`, copyWith, computed properties, `QuestionController` initial state, isSelected, selectAnswer (normal/guard/double-call), reset, usePowerUp — 20+ tests ✅ NEW
- `test/core/models/user_wallet_model_test.dart` — expanded: credits→coins, neuralXp→xp, synapseShards→diamonds field mapping, defaults, doubles, `UserWallet.empty` — 15+ tests ✅ NEW
- `test/game/controllers/coin_balance_notifier_test.dart` — add/deduct/canAfford/set/reset/persistence — 20+ tests ✅ NEW
- `test/game/controllers/energy_notifier_test.dart` — `EnergyState.copyWith`, `EnergyNotifier` initial state/canPlay*/useEnergy/addEnergy/syncWithServer — 25+ tests ✅ NEW
- `test/game/services/wallet_service_test.dart` — addCoins/addGems/spendCoins/spendGems/setBalances, independence — 20+ tests ✅ NEW
- `test/game/providers/profile_providers_test.dart` — `currentUserIdProvider` fallback chain (userId/email/playerName/guest), `PlayerProfileService`, `LocalAuthService.getStoredEmail` — 12+ tests ✅ NEW
- Many more — see `test/` directory tree

#### Still needed for 40% milestone:
- `AuthOperations` integration tests (Riverpod container wiring)
- Notification/background service tests

---

### 5. 🔐 Biometric Authentication (1 hour)

**Priority:** P3 - Low  
**Effort:** 1 hour  
**Status:** Premium feature, optional

#### What It Does:
- Login with fingerprint/Face ID
- Faster, more secure login
- Premium user feature

#### Implementation:

**Step 1: Add Package** (5 minutes)
```yaml
# pubspec.yaml
dependencies:
  local_auth: ^2.1.0
```

**Step 2: Add Permissions** (5 minutes)

Android (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
```

iOS (`ios/Runner/Info.plist`):
```xml
<key>NSFaceIDUsageDescription</key>
<string>We need Face ID to securely log you in</string>
```

**Step 3: Create BiometricAuthService** (30 minutes)

See `P2_P3_BIOMETRIC_GUIDE.md` for complete implementation.

**Step 4: Add to Login Flow** (20 minutes)
- Add biometric button to login screen
- Store encrypted credentials securely
- Auto-login with biometrics

---

### 6. 📊 Analytics & Crash Reporting (1 hour)

**Priority:** P3 - Medium  
**Effort:** 1 hour  
**Status:** Important for production

#### Option A: Firebase (Recommended)

**Step 1: Setup Firebase** (15 minutes)
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Add your app
3. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)

**Step 2: Add Packages** (5 minutes)
```yaml
dependencies:
  firebase_core: ^2.24.0
  firebase_analytics: ^10.7.0
  firebase_crashlytics: ^3.4.0
```

**Step 3: Initialize** (10 minutes)

In `main.dart`:
```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp();
  
  // Pass all uncaught errors to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  
  runApp(MyApp());
}
```

**Step 4: Track Events** (30 minutes)

Create `lib/core/services/analytics_tracking_service.dart`:
```dart
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  
  Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
  }
  
  Future<void> logSignup(String method) async {
    await _analytics.logSignUp(signUpMethod: method);
  }
  
  Future<void> logQuizStart(String category) async {
    await _analytics.logEvent(
      name: 'quiz_start',
      parameters: {'category': category},
    );
  }
}
```

#### Option B: Sentry (Alternative)

**Simpler setup, privacy-focused:**
```yaml
dependencies:
  sentry_flutter: ^7.0.0
```

```dart
import 'package:sentry_flutter/sentry_flutter.dart';

void main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = 'YOUR_SENTRY_DSN';
    },
    appRunner: () => runApp(MyApp()),
  );
}
```

---

## 📅 Recommended Implementation Timeline

### This Week (P2 - 1 hour total)
**Day 1 (30 min):**
- ✅ Add AuthHttpClient
- ✅ Update API service
- ✅ Test auto-refresh

**Day 2 (20 min):**
- ✅ Add error message handler
- ✅ Update login/signup screens
- ✅ Test error messages

**Day 3 (10 min):**
- ✅ Quick manual testing
- ✅ Fix any issues

**Result:** Seamless auth experience with auto-refresh

---

### Next Week (P3 - 3-4 hours)
**Monday (1 hour):**
- Add Firebase/Sentry
- Basic crash reporting

**Tuesday (2 hours):**
- Write key unit tests
- Test auth flows

**Wednesday (1 hour):**
- Add biometric auth (optional)
- Premium feature implementation

**Result:** Production-ready with monitoring

---

## 🎯 Priority Quick Reference

| Feature | Priority | Time | Impact | Status |
|---------|----------|------|--------|--------|
| Metadata Persistence | P2 | - | High | ✅ Done |
| Auto Token Refresh | P2 | 30m | High | ✅ Done |
| Error Messages | P2 | 20m | High | ✅ Done |
| Rewards Backend Wiring | P2 | - | High | ✅ Done |
| Skill Tree Hex Grid Layout | P2 | - | High | ✅ Done |
| Unit Tests (auth, arcade, skill tree) | P3 | 2h | Medium | ✅ In progress |
| Analytics | P3 | 1h | Medium | 📝 Guide (deferred) |
| Biometric Auth | P3 | 1h | Low | 📝 Guide (deferred) |

---

## 🚀 Quick Start Guide

### Implement P2 Today (50 minutes):

```bash
# 1. Add AuthHttpClient (5 min)
cp auth_http_client.dart lib/core/services/auth_http_client.dart

# 2. Add Error Messages (5 min)
cp auth_error_messages.dart lib/core/services/auth_error_messages.dart

# 3. Update providers (10 min)
# - Add authHttpClientProvider to riverpod_providers.dart

# 4. Update login screen (15 min)
# - Use AuthErrorMessages in error handling

# 5. Update API service (10 min)
# - Replace http.Client with AuthHttpClient

# 6. Test (5 min)
flutter run
# - Try login with expired token
# - Try login with wrong password
```

---

## 📚 Additional Resources

Detailed guides provided:
- `P2_P3_TESTING_GUIDE.md` - Complete test examples
- `P2_P3_BIOMETRIC_GUIDE.md` - Biometric auth implementation
- `P2_P3_ANALYTICS_GUIDE.md` - Analytics setup and tracking

---

## ✅ Success Criteria

### P2 Complete When:
- [ ] Token auto-refreshes before expiry
- [ ] 401 errors trigger auto-refresh
- [ ] User-friendly error messages shown
- [ ] No "session expired" interruptions

### P3 Complete When:
- [ ] Basic tests passing
- [ ] Crashes reported to Sentry/Firebase
- [ ] Key events tracked (login, signup, quiz start)
- [ ] Biometric login working (optional)

---

## 🎉 Expected Benefits

**After P2:**
- ✅ Seamless user experience
- ✅ No unexpected logouts
- ✅ Clear error messages
- ✅ Better user retention

**After P3:**
- ✅ Confident deployments
- ✅ Quick bug detection
- ✅ Data-driven decisions
- ✅ Premium user features

---

## 💡 Pro Tips

1. **Implement P2 first** - Biggest UX impact, minimal effort
2. **Test incrementally** - Don't add everything at once
3. **Monitor analytics** - Let data guide future improvements
4. **Document decisions** - Future you will thank you

---

## 🆘 Need Help?

If stuck on any implementation:
1. Check the detailed guide for that feature
2. Review the code comments in provided files
3. Test each change individually
4. Roll back if something breaks

**Remember:** These are all enhancements. Your core auth is already working! 🎉
