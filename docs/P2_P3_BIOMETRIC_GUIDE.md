# Biometric Authentication Guide
## Fingerprint & Face ID for Trivia Tycoon

---

## Overview

Add biometric authentication (fingerprint, Face ID, Touch ID) to your app for:
- ✅ Faster login
- ✅ Better security
- ✅ Premium user feature
- ✅ Modern UX

**Time:** ~1 hour  
**Difficulty:** Medium  
**Priority:** P3 (Optional)

---

## Step 1: Add Package (5 minutes)

### pubspec.yaml
```yaml
dependencies:
  local_auth: ^2.1.0
  flutter_secure_storage: ^9.0.0  # For storing credentials
```

```bash
flutter pub get
```

---

## Step 2: Platform Setup (10 minutes)

### Android Configuration

**File:** `android/app/src/main/AndroidManifest.xml`

Add before `<application>`:
```xml
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
<uses-permission android:name="android.permission.USE_FINGERPRINT"/>
```

### iOS Configuration

**File:** `ios/Runner/Info.plist`

Add:
```xml
<key>NSFaceIDUsageDescription</key>
<string>We use Face ID to securely log you in to your account</string>
```

---

## Step 3: Create BiometricAuthService (20 minutes)

**File:** `lib/core/services/biometric_auth_service.dart`

```dart
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class BiometricAuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  static const String _biometricCredentialsKey = 'biometric_credentials';
  static const String _biometricEnabledKey = 'biometric_enabled';

  /// Check if device supports biometrics
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } on PlatformException {
      return false;
    }
  }

  /// Check if biometrics are available (device support + enrolled)
  Future<bool> isBiometricsAvailable() async {
    try {
      final canCheck = await canCheckBiometrics();
      if (!canCheck) return false;
      
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } on PlatformException {
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  /// Get user-friendly biometric type name
  Future<String> getBiometricTypeName() async {
    final types = await getAvailableBiometrics();
    
    if (types.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (types.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (types.contains(BiometricType.iris)) {
      return 'Iris';
    } else if (types.contains(BiometricType.strong)) {
      return 'Biometric';
    }
    
    return 'Biometric Authentication';
  }

  /// Authenticate with biometrics
  Future<bool> authenticate({String? reason}) async {
    try {
      final typeName = await getBiometricTypeName();
      
      return await _localAuth.authenticate(
        localizedReason: reason ?? 'Please authenticate to access your account',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e) {
      print('Biometric authentication error: ${e.message}');
      return false;
    }
  }

  /// Check if biometric login is enabled for this device
  Future<bool> isBiometricLoginEnabled() async {
    final enabled = await _secureStorage.read(key: _biometricEnabledKey);
    return enabled == 'true';
  }

  /// Enable biometric login and save credentials
  Future<void> enableBiometricLogin({
    required String email,
    required String password,
  }) async {
    // Authenticate before saving
    final authenticated = await authenticate(
      reason: 'Authenticate to enable biometric login',
    );
    
    if (!authenticated) {
      throw Exception('Authentication failed');
    }

    // Save encrypted credentials
    final credentials = jsonEncode({
      'email': email,
      'password': password,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    await _secureStorage.write(
      key: _biometricCredentialsKey,
      value: credentials,
    );
    
    await _secureStorage.write(
      key: _biometricEnabledKey,
      value: 'true',
    );
  }

  /// Disable biometric login and clear credentials
  Future<void> disableBiometricLogin() async {
    await _secureStorage.delete(key: _biometricCredentialsKey);
    await _secureStorage.delete(key: _biometricEnabledKey);
  }

  /// Authenticate and retrieve stored credentials
  Future<Map<String, String>?> authenticateAndGetCredentials() async {
    final enabled = await isBiometricLoginEnabled();
    if (!enabled) return null;

    final authenticated = await authenticate(
      reason: 'Authenticate to log in',
    );
    
    if (!authenticated) return null;

    final credentialsJson = await _secureStorage.read(
      key: _biometricCredentialsKey,
    );
    
    if (credentialsJson == null) return null;

    try {
      final credentials = jsonDecode(credentialsJson) as Map<String, dynamic>;
      return {
        'email': credentials['email'] as String,
        'password': credentials['password'] as String,
      };
    } catch (e) {
      print('Error parsing credentials: $e');
      return null;
    }
  }
}
```

---

## Step 4: Add to Riverpod Providers (5 minutes)

**File:** `lib/game/providers/riverpod_providers.dart`

```dart
/// Biometric authentication service
final biometricAuthServiceProvider = Provider<BiometricAuthService>((ref) {
  return BiometricAuthService();
});
```

---

## Step 5: Update Login Screen (15 minutes)

### Add Biometric Button

**File:** `lib/screens/login_screen.dart` (or your login screen)

```dart
class LoginScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  
  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }
  
  Future<void> _checkBiometric() async {
    final biometricService = ref.read(biometricAuthServiceProvider);
    final available = await biometricService.isBiometricsAvailable();
    final enabled = await biometricService.isBiometricLoginEnabled();
    
    setState(() {
      _biometricAvailable = available;
      _biometricEnabled = enabled;
    });
  }
  
  Future<void> _loginWithBiometric() async {
    final biometricService = ref.read(biometricAuthServiceProvider);
    
    try {
      final credentials = await biometricService.authenticateAndGetCredentials();
      
      if (credentials == null) {
        _showError('Biometric authentication failed');
        return;
      }
      
      // Use existing login method
      final authOps = ref.read(authOperationsProvider);
      await authOps.loginWithPassword(
        credentials['email']!,
        credentials['password']!,
      );
      
      // Navigate to home
      context.go('/home');
      
    } catch (e) {
      _showError('Login failed: ${e.toString()}');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ... existing login form ...
          
          // Biometric login button
          if (_biometricAvailable && _biometricEnabled)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: OutlinedButton.icon(
                onPressed: _loginWithBiometric,
                icon: Icon(Icons.fingerprint),
                label: Text('Login with Biometrics'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
```

---

## Step 6: Add Biometric Settings (10 minutes)

### Settings Screen Option

**File:** `lib/screens/settings/user_settings_screen.dart`

```dart
class BiometricSettingTile extends ConsumerStatefulWidget {
  @override
  ConsumerState<BiometricSettingTile> createState() => _BiometricSettingTileState();
}

class _BiometricSettingTileState extends ConsumerState<BiometricSettingTile> {
  bool _isEnabled = false;
  bool _isAvailable = false;
  String _biometricType = 'Biometric';
  
  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }
  
  Future<void> _checkBiometric() async {
    final service = ref.read(biometricAuthServiceProvider);
    final available = await service.isBiometricsAvailable();
    final enabled = await service.isBiometricLoginEnabled();
    final type = await service.getBiometricTypeName();
    
    setState(() {
      _isAvailable = available;
      _isEnabled = enabled;
      _biometricType = type;
    });
  }
  
  Future<void> _toggleBiometric(bool value) async {
    final service = ref.read(biometricAuthServiceProvider);
    
    if (value) {
      // Enable biometric
      final email = await _getCurrentEmail();
      final password = await _showPasswordDialog();
      
      if (email == null || password == null) return;
      
      try {
        await service.enableBiometricLogin(
          email: email,
          password: password,
        );
        setState(() => _isEnabled = true);
        _showSuccess('Biometric login enabled');
      } catch (e) {
        _showError('Failed to enable biometric login');
      }
    } else {
      // Disable biometric
      await service.disableBiometricLogin();
      setState(() => _isEnabled = false);
      _showSuccess('Biometric login disabled');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (!_isAvailable) {
      return SizedBox.shrink(); // Hide if not available
    }
    
    return SwitchListTile(
      title: Text('$_biometricType Login'),
      subtitle: Text(_isEnabled 
        ? 'Enabled - Quick login with $_biometricType'
        : 'Disabled - Enter password required'),
      secondary: Icon(Icons.fingerprint),
      value: _isEnabled,
      onChanged: _toggleBiometric,
    );
  }
  
  Future<String?> _getCurrentEmail() async {
    // Get from secure storage or profile service
    final secureStorage = ref.read(secureStorageProvider);
    return await secureStorage.getSecret('user_email');
  }
  
  Future<String?> _showPasswordDialog() async {
    String? password;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter Password'),
        content: TextField(
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: 'Enter your password',
          ),
          onChanged: (value) => password = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Confirm'),
          ),
        ],
      ),
    );
    
    return password;
  }
}
```

---

## Step 7: Auto-Enable on Successful Login (Optional)

### Prompt User After First Login

```dart
// In login success callback
Future<void> _onLoginSuccess(String email, String password) async {
  final biometricService = ref.read(biometricAuthServiceProvider);
  final available = await biometricService.isBiometricsAvailable();
  final enabled = await biometricService.isBiometricLoginEnabled();
  
  if (available && !enabled) {
    // Show prompt to enable biometric
    final shouldEnable = await _showBiometricPrompt();
    
    if (shouldEnable) {
      try {
        await biometricService.enableBiometricLogin(
          email: email,
          password: password,
        );
        _showSuccess('Biometric login enabled! 🎉');
      } catch (e) {
        // User declined or error occurred
      }
    }
  }
  
  // Continue to home
  context.go('/home');
}

Future<bool> _showBiometricPrompt() async {
  final service = ref.read(biometricAuthServiceProvider);
  final typeName = await service.getBiometricTypeName();
  
  return await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Enable $typeName?'),
      content: Text(
        'Login faster and more securely with $typeName. '
        'You can disable this anytime in Settings.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Not Now'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Enable'),
        ),
      ],
    ),
  ) ?? false;
}
```

---

## Security Best Practices

### 1. **Always Encrypt Credentials**
✅ Using `flutter_secure_storage` - encrypted by default

### 2. **Verify Authentication Before Saving**
✅ Implemented in `enableBiometricLogin()`

### 3. **Clear on Logout**
```dart
// In logout method
final biometricService = ref.read(biometricAuthServiceProvider);
await biometricService.disableBiometricLogin();
```

### 4. **Add Expiration (Optional)**
Store timestamp and invalidate after X days:
```dart
final timestamp = credentials['timestamp'];
final savedDate = DateTime.parse(timestamp);
final daysSince = DateTime.now().difference(savedDate).inDays;

if (daysSince > 30) {
  // Require re-authentication
  await disableBiometricLogin();
  return null;
}
```

---

## Testing

### Test on Physical Devices

Biometrics don't work reliably on emulators. Test on:
- Android phone with fingerprint
- iPhone with Face ID
- iPhone with Touch ID

### Test Scenarios

- [ ] Enable biometric on first login
- [ ] Login with biometric
- [ ] Disable biometric in settings
- [ ] Try login with wrong fingerprint (should fail)
- [ ] Logout and verify credentials cleared
- [ ] Re-enable biometric
- [ ] App restart and biometric still works

---

## Error Handling

### Common Issues & Solutions

**Issue:** "Biometric not available"  
**Fix:** Check device has biometric enrolled in Settings

**Issue:** Authentication fails  
**Fix:** User cancelled or wrong fingerprint - show friendly message

**Issue:** Credentials not found  
**Fix:** Biometric was disabled - redirect to regular login

**Issue:** Permission denied  
**Fix:** Check AndroidManifest.xml and Info.plist permissions

---

## UX Recommendations

### 1. **Show Icon Based on Type**
```dart
Icon _getBiometricIcon() {
  switch (_biometricType) {
    case 'Face ID':
      return Icon(Icons.face);
    case 'Fingerprint':
      return Icon(Icons.fingerprint);
    default:
      return Icon(Icons.security);
  }
}
```

### 2. **Graceful Fallback**
Always show password login as backup option

### 3. **Clear Messaging**
```dart
if (_biometricEnabled) {
  Text('Tap to login with ${_biometricType}');
} else {
  Text('Enable ${_biometricType} for quick login');
}
```

### 4. **Premium Badge (Optional)**
```dart
if (isPremium) {
  Badge(
    label: Text('PREMIUM'),
    child: BiometricLoginButton(),
  );
}
```

---

## Analytics Tracking

Track biometric usage:

```dart
// When enabled
analytics.logEvent(
  name: 'biometric_enabled',
  parameters: {'type': biometricType},
);

// When used for login
analytics.logLogin(loginMethod: 'biometric');

// When disabled
analytics.logEvent(name: 'biometric_disabled');
```

---

## Checklist

Setup:
- [ ] Add local_auth package
- [ ] Add flutter_secure_storage
- [ ] Configure Android permissions
- [ ] Configure iOS permissions
- [ ] Create BiometricAuthService
- [ ] Add Riverpod provider

Implementation:
- [ ] Add biometric button to login screen
- [ ] Add toggle in settings
- [ ] Prompt on first login
- [ ] Clear on logout
- [ ] Test on physical device

Security:
- [ ] Credentials encrypted
- [ ] Authentication required before saving
- [ ] Cleared on logout
- [ ] Expiration implemented (optional)

---

## Expected Benefits

After implementation:
- ✅ 50% faster login time
- ✅ Better user retention (easier to come back)
- ✅ Premium feature differentiator
- ✅ Modern, secure UX

**Users love quick login!** 🚀🔐
