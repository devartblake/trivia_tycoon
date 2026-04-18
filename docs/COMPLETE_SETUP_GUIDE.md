# 🎯 COMPLETE SPRINT 1 SETUP GUIDE
## Custom Login + API Fixes + Ready for Sprint 2

---

## 📊 Current Status

Blake, I've analyzed your files and created custom solutions for your specific project structure:

### ✅ What You Have:
- Custom LoginScreen (not using login_card.dart) ✅
- AuthErrorMessages already imported ✅
- Two screens using old API (season_rewards, ranked_leaderboard) ⚠️
- Backend auth working ✅

### 🔧 What Needs Fixing:
1. **Login error handling** - 1 line change
2. **SynaptixApiClient** - Replace file (backward compatibility)

**Total time:** 3 minutes ⏱️

---

## 🚀 STEP-BY-STEP IMPLEMENTATION

### STEP 1: Fix Login Error Messages (2 minutes)

**File:** `lib/screens/login_screen.dart`

**Location:** Lines 234-237 (catch block in _handleLogin method)

**Replace this:**
```dart
} catch (e) {
  _showErrorSnackBar('Login failed: ${e.toString()}');
  setState(() => _isLoading = false);
}
```

**With this:**
```dart
} catch (e) {
  final errorMessage = ConfigService.useBackendAuth
      ? (_isSignUpMode 
          ? AuthErrorMessages.getSignupErrorMessage(e)
          : AuthErrorMessages.getLoginErrorMessage(e))
      : 'Login failed: ${e.toString()}';
  
  _showErrorSnackBar(errorMessage);
  setState(() => _isLoading = false);
}
```

**What this does:**
- ✅ Shows user-friendly errors for backend auth
- ✅ Keeps existing behavior for mock auth
- ✅ Supports both login and signup modes
- ✅ No UI changes

---

### STEP 2: Fix API Client (1 minute)

**File:** Replace `lib/core/networkting/tycoon_api_client.dart`

```bash
# Copy the fixed version
cp tycoon_api_client_FIXED.dart lib/core/networkting/tycoon_api_client.dart
```

**What this does:**
- ✅ Adds `getJson()` method (backward compatible)
- ✅ Fixes season_rewards_preview_screen.dart
- ✅ Fixes ranked_leaderboard_screen.dart
- ✅ Keeps all enhanced methods
- ✅ Uses HttpClient with auto-refresh

**No screen modifications needed!**

---

### STEP 3: Add Provider (From Sprint 1 original guide)

**File:** `lib/game/providers/riverpod_providers.dart`

**Add this provider** after `coreAuthServiceProvider` (around line 177):

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
    },
  );
});
```

**Make sure the import is at the top:**
```dart
import '../../core/services/auth_http_client.dart';
```

---

## ✅ Verification Checklist

After making all changes:

### Compile Check:
```bash
flutter pub get
flutter analyze
```
**Expected:** No errors ✅

### Test Login Errors:
1. **Wrong Password:**
   - Try login with wrong password
   - Should see: "Invalid email or password" ✅

2. **Network Error:**
   - Turn off wifi
   - Try login
   - Should see: "Cannot connect to server..." ✅

3. **Signup Existing Email:**
   - Switch to signup mode
   - Use existing email
   - Should see: "An account with this email already exists..." ✅

### Test Screens:
4. **Season Rewards:**
   - Navigate to season rewards screen
   - Should load without errors ✅

5. **Ranked Leaderboard:**
   - Navigate to ranked leaderboard
   - Should load and display data ✅

---

## 📁 Files Modified Summary

```
✅ MODIFIED:
lib/screens/
└── login_screen.dart                  [1 catch block updated]

lib/core/networkting/
└── tycoon_api_client.dart             [File replaced]

lib/game/providers/
└── riverpod_providers.dart            [1 provider added]

✅ UNCHANGED (work as-is):
lib/screens/
├── season_rewards_preview_screen.dart  [No changes needed]
└── ranked_leaderboard_screen.dart      [No changes needed]

✅ NOT MODIFIED (not used):
lib/ui_components/login/cards/
├── login_card.dart                     [Different system]
└── signup_confirm_card.dart            [Different system]
```

---

## 🎯 What You Get

### Before:
```
❌ "Login failed: Exception: 401 Unauthorized"
❌ "Login failed: SocketException: Connection refused"
❌ Season screens broken (getJson missing)
❌ No auto-refresh
```

### After:
```
✅ "Invalid email or password"
✅ "Cannot connect to server. Please check your connection."
✅ Season screens working
✅ Auto token refresh enabled
✅ Professional error messages
```

---

## 📋 Complete Implementation Code

### 1. login_screen.dart (Updated Catch Block)

```dart
Future<void> _handleLogin() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  final email = _emailController.text.trim();
  final password = _passwordController.text;

  await Future.delayed(const Duration(milliseconds: 1500));

  try {
    final authOps = ref.read(authOperationsProvider);
    final multiProfileService = ref.read(multiProfileServiceProvider);
    final serviceManager = ref.read(serviceManagerProvider);

    if (ConfigService.useBackendAuth) {
      if (_isSignUpMode) {
        await authOps.signup(email, password);
      } else {
        await authOps.loginWithPassword(email, password);
      }
    } else {
      // Mock auth logic...
      if (!mockUsers.containsKey(email)) {
        _showErrorSnackBar('User does not exist');
        setState(() => _isLoading = false);
        return;
      }

      final mockUser = mockUsers[email]!;
      if (mockUser.password != password) {
        _showErrorSnackBar('Incorrect password');
        setState(() => _isLoading = false);
        return;
      }

      await authOps.login(email);
      final authService = ref.read(authServiceProvider);
      await authService.secureStorage.setSecret('user_role', mockUser.role);
      await authService.secureStorage
          .setSecret('is_premium', mockUser.isPremium.toString());
    }

    // Multi-profile logic...
    final existingProfiles = await multiProfileService.getAllProfiles();

    if (existingProfiles.isNotEmpty) {
      final activeProfile = await multiProfileService.getActiveProfile();
      if (activeProfile != null) {
        ref.read(activeProfileStateProvider.notifier).state = activeProfile;
        ref.read(hasSeenIntroProvider.notifier).state = true;
        ref.read(hasCompletedProfileProvider.notifier).state = true;
      }
    } else {
      final playerProfileService = serviceManager.playerProfileService;
      final existingName = await playerProfileService.getPlayerName();

      if (existingName != 'Player' && existingName.isNotEmpty) {
        final existingAvatar = await playerProfileService.getAvatar();
        final existingCountry = await playerProfileService.getCountry();
        final existingAgeGroup = await playerProfileService.getAgeGroup();

        final migratedProfile = await multiProfileService.createProfile(
          name: existingName,
          avatar: existingAvatar,
          country: existingCountry,
          ageGroup: existingAgeGroup,
        );

        if (migratedProfile != null) {
          await multiProfileService.setActiveProfile(migratedProfile.id);
          ref.read(activeProfileStateProvider.notifier).state = migratedProfile;
          ref.read(hasSeenIntroProvider.notifier).state = true;
          ref.read(hasCompletedProfileProvider.notifier).state = true;
        }
      } else {
        ref.read(hasSeenIntroProvider.notifier).state = false;
        ref.read(hasCompletedProfileProvider.notifier).state = false;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Complete onboarding to finish setting up your account.'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }

    setState(() => _isLoading = false);

    if (mounted) {
      final needsOnboarding = !(ref.read(hasCompletedProfileProvider));
      context.go(needsOnboarding ? '/profile-setup' : '/home');
    }
  } catch (e) {
    // ✅✅✅ UPDATED SECTION - USER-FRIENDLY ERRORS ✅✅✅
    final errorMessage = ConfigService.useBackendAuth
        ? (_isSignUpMode 
            ? AuthErrorMessages.getSignupErrorMessage(e)
            : AuthErrorMessages.getLoginErrorMessage(e))
        : 'Login failed: ${e.toString()}';
    
    _showErrorSnackBar(errorMessage);
    setState(() => _isLoading = false);
  }
}
```

### 2. riverpod_providers.dart (Add Provider)

```dart
// Add this import at top with other auth imports
import '../../core/services/auth_http_client.dart';

// Add this provider after coreAuthServiceProvider
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
    },
  );
});
```

---

## ⏱️ Time Breakdown

- Login error handling: 2 min ⏱️
- Replace API client: 1 min ⏱️
- Add provider: 2 min ⏱️
- Test: 2 min ⏱️

**Total: 7 minutes** 🎯

---

## 🎉 Success Criteria

Sprint 1 is complete when:

✅ No compilation errors
✅ Login shows "Invalid email or password" (not technical error)
✅ Network errors show friendly message
✅ Signup errors show friendly message
✅ Season screens load without errors
✅ Leaderboard screen loads without errors
✅ Logs show token auto-refresh messages

---

## 🚀 After Sprint 1

You'll have:
- ✅ Professional error messages
- ✅ Automatic token refresh
- ✅ All screens working
- ✅ Backward compatible API client
- ✅ Production-ready auth UX

**Ready for Sprint 2:** Networking layer (optional)

---

## 📚 Reference Documents Provided

1. **SPRINT_1_CUSTOM_LOGIN.md** - Detailed guide for your login screen
2. **API_CLIENT_FIX_GUIDE.md** - Explains API client fixes
3. **tycoon_api_client_FIXED.dart** - Updated API client file

---

## 💡 Pro Tips

1. **Test incrementally:** Make one change, test, then move to next
2. **Commit after each step:** Easy to rollback if needed
3. **Check logs:** Look for "[Auth]" messages confirming auto-refresh
4. **Keep mock auth:** Good for offline testing

---

## 🆘 Troubleshooting

**Issue:** "AuthHttpClient not found"  
**Fix:** Add import in riverpod_providers.dart

**Issue:** "getJson method not found"  
**Fix:** Make sure you replaced tycoon_api_client.dart

**Issue:** Still seeing technical errors  
**Fix:** Verify you updated the catch block in login_screen.dart

---

## ✅ Ready to Start?

1. Read SPRINT_1_CUSTOM_LOGIN.md (optional - for details)
2. Update login_screen.dart catch block
3. Replace tycoon_api_client.dart
4. Add authHttpClientProvider
5. Test everything
6. Celebrate! 🎉

**Then move to Sprint 2 (networking) or ship what you have!**

Your call - Sprint 1 alone gives you production-ready auth! 🚀
