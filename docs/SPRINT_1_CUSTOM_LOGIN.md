# SPRINT 1 - CUSTOM IMPLEMENTATION FOR YOUR LOGIN SCREEN
## Updated for Your Project Structure

---

## 🎯 Analysis Complete

I've analyzed your files. Good news:

✅ **You already imported AuthErrorMessages!** (line 9 of login_screen.dart)
✅ **Your login screen is custom-built** (doesn't use login_card.dart components)
✅ **You only need ONE simple change!**

**Your login_card.dart is NOT used** by LoginScreen - it's part of a different auth system (auth_card_builder.dart). We'll leave it alone.

---

## 📝 SPRINT 1: Single File Update

### File: `lib/screens/login_screen.dart`

**Location:** Line 234-235 (inside the catch block of _handleLogin())

**Current Code:**
```dart
} catch (e) {
  _showErrorSnackBar('Login failed: ${e.toString()}');
  setState(() => _isLoading = false);
}
```

**Updated Code:**
```dart
} catch (e) {
  final errorMessage = ConfigService.useBackendAuth
      ? AuthErrorMessages.getLoginErrorMessage(e)
      : 'Login failed: ${e.toString()}';
  _showErrorSnackBar(errorMessage);
  setState(() => _isLoading = false);
}
```

**Why this approach:**
- ✅ Uses friendly errors for backend auth
- ✅ Keeps existing behavior for mock auth
- ✅ Minimal change (safer)
- ✅ No UI changes needed

---

## 🔧 OPTIONAL: Better Signup Error Handling

If you want to also improve signup errors:

**Location:** Line 150 (inside _handleLogin when _isSignUpMode is true)

**Add this helper method** to the `_LoginScreenState` class:

```dart
String _getAuthErrorMessage(dynamic error, {bool isSignup = false}) {
  if (!ConfigService.useBackendAuth) {
    // Mock auth - keep simple messages
    return error.toString();
  }
  
  // Backend auth - use friendly messages
  return isSignup
      ? AuthErrorMessages.getSignupErrorMessage(error)
      : AuthErrorMessages.getLoginErrorMessage(error);
}
```

**Then update the catch block** to use it:

```dart
} catch (e) {
  final errorMessage = _getAuthErrorMessage(e, isSignup: _isSignUpMode);
  _showErrorSnackBar(errorMessage);
  setState(() => _isLoading = false);
}
```

---

## ✅ Complete Updated Code Section

Here's the complete updated _handleLogin method (lines 131-238):

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
      // Backend authentication
      if (_isSignUpMode) {
        await authOps.signup(email, password);
      } else {
        await authOps.loginWithPassword(email, password);
      }
    } else {
      // Legacy mock authentication
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

    // Handle multi-profile migration/loading
    final existingProfiles = await multiProfileService.getAllProfiles();

    if (existingProfiles.isNotEmpty) {
      final activeProfile = await multiProfileService.getActiveProfile();

      if (activeProfile != null) {
        ref.read(activeProfileStateProvider.notifier).state = activeProfile;
        ref.read(hasSeenIntroProvider.notifier).state = true;
        ref.read(hasCompletedProfileProvider.notifier).state = true;
      }
    } else {
      // Migrate existing profile data if present
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
        // New user - needs onboarding
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
    // ✅ UPDATED: User-friendly error messages
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

---

## 🎯 What Changed?

**Before (Line 235):**
```dart
_showErrorSnackBar('Login failed: ${e.toString()}');
```

**After:**
```dart
final errorMessage = ConfigService.useBackendAuth
    ? (_isSignUpMode 
        ? AuthErrorMessages.getSignupErrorMessage(e)
        : AuthErrorMessages.getLoginErrorMessage(e))
    : 'Login failed: ${e.toString()}';

_showErrorSnackBar(errorMessage);
```

---

## 📊 Error Message Examples

### Before:
```
❌ Login failed: Exception: Invalid credentials
❌ Login failed: SocketException: Connection refused
❌ Login failed: Exception: 409 Conflict
```

### After:
```
✅ Invalid email or password. Please try again.
✅ Cannot connect to server. Please check your internet connection.
✅ An account with this email already exists. Please log in instead.
```

---

## ✅ Testing Sprint 1

After making the change:

1. **Test Wrong Password:**
   ```
   Email: test@test.com
   Password: wrongpassword
   Expected: "Invalid email or password"
   ```

2. **Test Network Error:**
   ```
   - Turn off wifi
   - Try to login
   Expected: "Cannot connect to server..."
   ```

3. **Test Existing Email (signup):**
   ```
   - Switch to signup mode
   - Use existing email
   Expected: "An account with this email already exists..."
   ```

4. **Test Success:**
   ```
   - Use correct credentials
   Expected: Login successful, navigate to home
   ```

---

## 🚫 What NOT to Change

**Leave these alone:**
- Don't modify login_card.dart (it's not used by your screen)
- Don't modify signup_confirm_card.dart (different system)
- Don't modify the mock auth error messages (lines 157, 164) - they're already user-friendly
- Don't change _showErrorSnackBar method - it's perfect as-is

---

## ⏱️ Time Estimate

**Actual time:** 2 minutes
- Copy the updated catch block
- Paste into login_screen.dart
- Save
- Test

**That's Sprint 1 for your custom login screen!** ✅

---

## 🎯 Summary

**What you're doing:**
- ✅ Adding user-friendly error messages to backend auth
- ✅ Keeping mock auth as-is
- ✅ Supporting both login and signup modes
- ✅ Minimal code change (3 lines)

**What you're NOT doing:**
- ❌ Changing UI/design
- ❌ Modifying login_card.dart
- ❌ Restructuring the login flow
- ❌ Breaking existing functionality

**Impact:**
- ⭐⭐⭐⭐⭐ Better UX
- ⭐⭐⭐⭐⭐ Professional error messages
- ⭐⭐⭐⭐⭐ No UI changes needed

---

## 📋 Checklist

- [ ] Update catch block in _handleLogin (line 234-237)
- [ ] Save file
- [ ] Run `flutter analyze` (should pass)
- [ ] Run app
- [ ] Test wrong password
- [ ] Test network error
- [ ] Test success case

**All checked? Sprint 1 complete!** 🎉

---

## 🚀 Next: Sprint 2

After Sprint 1 works, we'll fix the API client issues and move to Sprint 2 (networking).

But first, let's get this working! 💪
