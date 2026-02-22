# SPRINT 1: P2 Complete Integration Guide
## Auto-Refresh + Error Messages (30 minutes)

---

## 🎯 Goal
Wire up the AuthHttpClient and error messages you've already added.

**What Blake Has:**
✅ auth_http_client.dart (complete)
✅ auth_error_messages.dart (complete)
✅ auth_token_store.dart with metadata (complete)

**What We Need:**
🔧 Add provider for AuthHttpClient
🔧 Update login/signup screens with error handling
🔧 Test everything

---

## Step 1: Add AuthHttpClient Provider (5 minutes)

### File: `lib/game/providers/riverpod_providers.dart`

**Add this import at the top:**
```dart
import '../../core/services/auth_http_client.dart';
```

**Add this provider after `coreAuthServiceProvider` (around line 177):**
```dart
/// Provides authenticated HTTP client with auto-refresh
final authHttpClientProvider = Provider<AuthHttpClient>((ref) {
  return AuthHttpClient(
    ref.watch(coreAuthServiceProvider),
    ref.watch(authTokenStoreProvider),
    autoRefresh: true,
    onTokenRefreshed: () {
      debugPrint('[Auth] ✅ Token auto-refreshed');
    },
    onRefreshFailed: (error) {
      debugPrint('[Auth] ❌ Refresh failed: $error');
      // Optional: Navigate to login or show notification
    },
  );
});
```

**Location:** Insert between `coreAuthServiceProvider` and `secureStorageProvider`

---

## Step 2: Update Login Screen Error Handling (10 minutes)

### File: Find your login screen (likely one of these):
- `lib/screens/login_screen.dart`
- `lib/ui_components/login/cards/login_card.dart`
- `lib/ui_components/login/trivia_login.dart`

### Add import at top:
```dart
import 'package:trivia_tycoon/core/services/auth_error_messages.dart';
```

### Find the login button handler and update:

**Before:**
```dart
Future<void> _handleLogin() async {
  try {
    await authOps.loginWithPassword(email, password);
    // Navigate to home
    context.go('/home');
  } catch (e) {
    setState(() {
      _errorMessage = 'Login failed: $e'; // ❌ Technical error
    });
  }
}
```

**After:**
```dart
Future<void> _handleLogin() async {
  try {
    await authOps.loginWithPassword(email, password);
    // Navigate to home
    context.go('/home');
  } catch (e) {
    setState(() {
      _errorMessage = AuthErrorMessages.getLoginErrorMessage(e); // ✅ User-friendly
    });
  }
}
```

### Alternative if using a different error display method:
```dart
catch (e) {
  final message = AuthErrorMessages.getLoginErrorMessage(e);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
```

---

## Step 3: Update Signup Screen Error Handling (10 minutes)

### File: Find your signup screen (likely one of these):
- `lib/screens/login_screen.dart` (if combined with login)
- `lib/ui_components/login/cards/signup_card.dart` 
- Similar to login screen

### Add same import:
```dart
import 'package:trivia_tycoon/core/services/auth_error_messages.dart';
```

### Update signup handler:

**Before:**
```dart
Future<void> _handleSignup() async {
  try {
    await authOps.signup(email, password, extra: {...});
    context.go('/onboarding');
  } catch (e) {
    setState(() {
      _errorMessage = 'Signup failed: $e'; // ❌ Technical
    });
  }
}
```

**After:**
```dart
Future<void> _handleSignup() async {
  try {
    await authOps.signup(email, password, extra: {...});
    context.go('/onboarding');
  } catch (e) {
    setState(() {
      _errorMessage = AuthErrorMessages.getSignupErrorMessage(e); // ✅ User-friendly
    });
  }
}
```

---

## Step 4: Optional - Update auth_providers.dart (5 minutes)

### File: `lib/game/providers/auth_providers.dart`

If you want centralized error handling, update `AuthOperations`:

```dart
/// Login user with password via backend (uses LoginManager)
Future<void> loginWithPassword(String email, String password) async {
  try {
    final loginManager = ref.read(loginManagerProvider);
    final secureStorage = ref.read(secureStorageProvider);

    await loginManager.login(email, password);
    await _updateRoleAndPremiumStatus(secureStorage);
    
    ref.read(isLoggedInSyncProvider.notifier).state = true;
  } catch (e) {
    // Rethrow with user-friendly message
    final message = AuthErrorMessages.getLoginErrorMessage(e);
    throw Exception(message);
  }
}

/// Signup user via backend (uses LoginManager)
Future<void> signup(
  String email,
  String password, {
  Map<String, dynamic>? extra,
}) async {
  try {
    final loginManager = ref.read(loginManagerProvider);
    final secureStorage = ref.read(secureStorageProvider);

    final signupData = SignupData.fromSignupForm(
      name: email,
      password: password,
      additionalSignupData: _convertToStringMap(extra),
    );

    await loginManager.signup(signupData);
    await _updateRoleAndPremiumStatus(secureStorage);
    
    ref.read(isLoggedInSyncProvider.notifier).state = true;
  } catch (e) {
    // Rethrow with user-friendly message
    final message = AuthErrorMessages.getSignupErrorMessage(e);
    throw Exception(message);
  }
}
```

---

## Step 5: Testing (5 minutes)

### Test Auto-Refresh:

**Option A - Manual Token Expiry:**
```dart
// Temporarily set a short expiry in auth_api_client.dart
// Line 49 & 99, change:
final expiresIn = data['expiresIn'] as int;
// To:
final expiresIn = 5; // 5 seconds for testing

// Then:
// 1. Login
// 2. Wait 6 seconds
// 3. Make any API call
// 4. Should see: "[AuthHttpClient] Token expired, refreshing..."
```

**Option B - Wait for Real Expiry:**
```dart
// 1. Login
// 2. Wait 15+ minutes
// 3. Make an API call
// 4. Should auto-refresh and succeed
```

### Test Error Messages:

1. **Wrong Password:**
   - Try login with wrong password
   - Should see: "Invalid email or password"
   - ❌ NOT: "Exception: 401" or "Invalid credentials"

2. **Existing Email:**
   - Try signup with existing email
   - Should see: "An account with this email already exists"
   - ❌ NOT: "Exception: 409" or "Conflict"

3. **Network Error:**
   - Turn off wifi/mobile data
   - Try login
   - Should see: "Cannot connect to server. Please check your internet connection."
   - ❌ NOT: "SocketException" or technical error

4. **Invalid Email:**
   - Try signup with invalid email
   - Should see: "Please enter a valid email address"

---

## Verification Checklist

After implementation, verify:

- [ ] No compilation errors
- [ ] `flutter analyze` shows no new warnings
- [ ] Login with correct credentials works
- [ ] Login with wrong password shows friendly error
- [ ] Signup with existing email shows friendly error
- [ ] Network errors show friendly messages
- [ ] Logs show `[AuthHttpClient]` messages when refreshing

---

## Expected Results

### Before Sprint 1:
```
User tries wrong password
→ Sees: "Login failed: Exception: Invalid credentials"
→ Confused 😕

User's token expires
→ Gets logged out unexpectedly
→ Loses progress
→ Frustrated 😤
```

### After Sprint 1:
```
User tries wrong password
→ Sees: "Invalid email or password. Please try again."
→ Understands what to do ✅

User's token expires
→ Auto-refreshes silently
→ Continues using app seamlessly
→ Happy 😊
```

---

## Common Issues & Solutions

### Issue 1: Provider Not Found
**Error:** `Provider authHttpClientProvider not found`  
**Fix:** Make sure you added the import and provider in riverpod_providers.dart

### Issue 2: Import Errors
**Error:** `auth_error_messages.dart not found`  
**Fix:** Check file is in `lib/core/services/` directory

### Issue 3: Still Seeing Technical Errors
**Problem:** Still showing "Exception: 401"  
**Fix:** Make sure you updated ALL try-catch blocks in login/signup

### Issue 4: Auto-Refresh Not Working
**Problem:** Still getting logged out  
**Fix:** 
1. Check `autoRefresh: true` in provider
2. Check logs for refresh messages
3. Verify token has expiry time

---

## Files Modified in Sprint 1

```
lib/game/providers/
└── riverpod_providers.dart          [MODIFIED] Added authHttpClientProvider

lib/screens/ (or lib/ui_components/login/)
├── login_screen.dart                [MODIFIED] Added error handling
└── signup screen file               [MODIFIED] Added error handling

lib/game/providers/
└── auth_providers.dart              [OPTIONAL] Centralized error handling
```

---

## Next Steps

After Sprint 1 complete:
✅ P2 is DONE!
✅ Auto-refresh working
✅ Error messages user-friendly

**Ready for Sprint 2?**
- Sprint 2: Complete networking layer (http_client, ws_client, etc.)
- Sprint 3: Optional P3 features (tests, analytics, biometric)

**Or ship now?**
Your auth system is production-ready after Sprint 1! 🚀

Sprint 2 and 3 are enhancements, not requirements.

---

## Time Breakdown

- Step 1: Provider (5 min) ⏱️
- Step 2: Login errors (10 min) ⏱️
- Step 3: Signup errors (10 min) ⏱️
- Step 4: Optional centralized (5 min) ⏱️
- Step 5: Testing (5 min) ⏱️

**Total:** 30-35 minutes 🎯

---

## Success Criteria

Sprint 1 is complete when:

✅ AuthHttpClient provider added
✅ Login shows friendly errors
✅ Signup shows friendly errors
✅ Tokens auto-refresh (verify in logs)
✅ No compilation errors
✅ App runs successfully
✅ All test scenarios pass

**Then you have a world-class auth system!** 🌟
