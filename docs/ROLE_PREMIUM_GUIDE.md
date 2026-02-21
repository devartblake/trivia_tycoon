# Role and Premium Status Handling Guide

## 🎯 Overview

This guide explains how to properly handle user roles and premium subscriptions in your authentication system.

---

## User Types Supported

### 1. **Regular Player** (Free)
- Role: `'player'`
- Premium: `false`
- Access: Basic features

### 2. **Premium Player** (Paid Subscription)
- Role: `'player'`
- Premium: `true`
- Access: All player features + premium content

### 3. **Admin**
- Role: `'admin'`
- Premium: `true` (typically)
- Access: All features + admin panel

### 4. **Moderator** (Optional)
- Role: `'moderator'`
- Premium: `true` (typically)
- Access: Content moderation tools

---

## Backend Response Format

Your backend should return user metadata in the response:

### Login/Signup Response
```json
{
  "accessToken": "jwt...",
  "refreshToken": "base64...",
  "expiresIn": 900,
  "userId": "guid",
  "user": {
    "id": "guid",
    "email": "user@example.com",
    "handle": "Player1",
    "role": "player",              // ← Single role
    "roles": ["player"],           // ← OR multiple roles
    "tier": "free",                // ← Tier system
    "isPremium": false,            // ← Premium status
    "subscriptionStatus": "none",  // ← Subscription details
    "mmr": 1000
  }
}
```

### Supported Field Names

The system automatically detects multiple field name variations:

**Role:**
- `role` (single string)
- `roles` (array of strings)
- `tier` (mapped to role)

**Premium Status:**
- `isPremium` (boolean)
- `is_premium` (boolean)
- `premium` (boolean)
- `subscriptionStatus` (string: "active", "premium", "none")
- `tier` (string: "premium", "pro", "vip")

---

## How It Works

### 1. Backend Returns User Data
```json
{
  "user": {
    "role": "player",
    "isPremium": true,
    "tier": "premium"
  }
}
```

### 2. AuthApiClient Extracts Metadata
```dart
// In auth_api_client.dart
Map<String, dynamic> _extractMetadata(Map<String, dynamic> response) {
  final metadata = <String, dynamic>{};
  
  if (response.containsKey('user')) {
    final user = response['user'];
    metadata.addAll(user);  // Copy all user fields
  }
  
  return metadata;
}
```

### 3. AuthSession Stores Metadata
```dart
AuthSession(
  accessToken: "jwt...",
  refreshToken: "base64...",
  userId: "guid",
  metadata: {
    "role": "player",
    "isPremium": true,
    "tier": "premium",
    // ... other user fields
  }
)
```

### 4. AuthTokenStore Persists Metadata
```dart
// Saves to Hive
await _box.put('auth_metadata', jsonEncode(metadata));

// Loads from Hive
final metadataJson = _box.get('auth_metadata');
final metadata = jsonDecode(metadataJson);
```

### 5. LoginManager Extracts and Applies
```dart
await _extractAndStoreRole(session);          // → 'player'
await _extractAndStorePremiumStatus(session);  // → true

// Stores in:
// - ProfileService (persistent)
// - SecureStorage (quick access)
```

---

## Files Updated

### 1. **SignupData** (No Changes Needed)
Already supports `additionalSignupData` map:
```dart
SignupData.fromSignupForm(
  name: email,
  password: password,
  additionalSignupData: {
    'Username': 'Player1',
    'Country': 'US',
  }
)
```

### 2. **auth_providers.dart** → `auth_providers_CORRECTED.dart`
**Key Changes:**
- Fixed `SignupData` constructor (use `fromSignupForm`)
- Added `_updateRoleAndPremiumStatus()` method
- Reads role/premium from ProfileService after LoginManager sets it

### 3. **LoginManager** → `LoginManager_ENHANCED.dart`
**Key Changes:**
- Added `_extractAndStoreRole()` - Extracts role from session metadata
- Added `_extractAndStorePremiumStatus()` - Extracts premium from session metadata
- Added `_mapTierToRole()` - Maps tier to role
- Added `_isPremiumTier()` - Checks if tier indicates premium
- Added `isPremiumUser()`, `isAdminUser()`, `getUserRole()` helper methods

### 4. **AuthSession** → `auth_session_enhanced.dart`
**Key Changes:**
- Added `metadata` field to store user info
- Added getters: `role`, `roles`, `isPremium`, `tier`
- Added `fromJson()` and `toJson()` for serialization

### 5. **AuthApiClient** → `auth_api_client_metadata_updates.dart`
**Key Changes:**
- Added `_extractMetadata()` method
- Parses `user` object from backend response
- Includes metadata in AuthSession

### 6. **AuthTokenStore** → `auth_token_store_enhanced.dart`
**Key Changes:**
- Added `_metadataKey` for storing metadata
- Persists metadata as JSON string in Hive
- Added `getRole()` and `isPremium()` helper methods

---

## Usage Examples

### Check if User is Premium
```dart
final loginManager = ref.read(loginManagerProvider);
final isPremium = await loginManager.isPremiumUser();

if (isPremium) {
  // Show premium features
} else {
  // Show upgrade prompt
}
```

### Check if User is Admin
```dart
final loginManager = ref.read(loginManagerProvider);
final isAdmin = await loginManager.isAdminUser();

if (isAdmin) {
  // Show admin panel
}
```

### Get User's Role
```dart
final loginManager = ref.read(loginManagerProvider);
final role = await loginManager.getUserRole();

switch (role) {
  case 'admin':
    // Admin features
    break;
  case 'moderator':
    // Moderator features
    break;
  case 'player':
  default:
    // Player features
    break;
}
```

### Access from ProfileService
```dart
final profileService = ref.read(playerProfileServiceProvider);

// Check premium status
final isPremium = await profileService.isPremiumUser();

// Get role
final role = await profileService.getUserRole();

// Get all roles
final roles = await profileService.getUserRoles();
```

### Access from SecureStorage
```dart
final secureStorage = ref.read(secureStorageProvider);

// Get role
final role = await secureStorage.getSecret('user_role');

// Get premium status
final isPremiumStr = await secureStorage.getSecret('is_premium');
final isPremium = isPremiumStr == 'true';
```

---

## Implementation Steps

### Step 1: Update AuthSession Model
Add the enhanced AuthSession from `auth_session_enhanced.dart` to your `auth_service.dart` or create a separate file.

### Step 2: Update AuthTokenStore
Replace your AuthTokenStore with `auth_token_store_enhanced.dart` to add metadata persistence.

### Step 3: Update AuthApiClient
Add the `_extractMetadata()` method from `auth_api_client_metadata_updates.dart` to your AuthApiClient.

Update `login()` and `signup()` methods to:
```dart
final metadata = _extractMetadata(data);
return AuthSession(
  // ... tokens
  metadata: metadata,
);
```

### Step 4: Update LoginManager
Replace your LoginManager with `LoginManager_ENHANCED.dart`.

This adds:
- `_extractAndStoreRole()`
- `_extractAndStorePremiumStatus()`
- Helper methods for checking user status

### Step 5: Update auth_providers.dart
Replace with `auth_providers_CORRECTED.dart`.

This fixes:
- SignupData constructor usage
- Role/premium status handling after login/signup

### Step 6: Test Complete Flow
```dart
// Signup
await authOps.signup('test@example.com', 'password');

// Check role
final role = await loginManager.getUserRole();
print('Role: $role');  // Should print: 'player'

// Check premium
final isPremium = await loginManager.isPremiumUser();
print('Premium: $isPremium');  // Should print: false

// Check from Hive
final session = tokenStore.load();
print('Metadata: ${session.metadata}');
```

---

## Backend Requirements

### Required Fields in Response

**Minimum (for basic functionality):**
```json
{
  "accessToken": "jwt...",
  "refreshToken": "base64...",
  "expiresIn": 900,
  "userId": "guid"
}
```

**Recommended (for role/premium features):**
```json
{
  "accessToken": "jwt...",
  "refreshToken": "base64...",
  "expiresIn": 900,
  "userId": "guid",
  "user": {
    "role": "player",
    "isPremium": false
  }
}
```

**Comprehensive (best practice):**
```json
{
  "accessToken": "jwt...",
  "refreshToken": "base64...",
  "expiresIn": 900,
  "userId": "guid",
  "user": {
    "id": "guid",
    "email": "user@example.com",
    "handle": "Player1",
    "role": "player",
    "roles": ["player"],
    "tier": "free",
    "isPremium": false,
    "subscriptionStatus": "none",
    "mmr": 1000,
    "createdAt": "2024-01-01T00:00:00Z"
  }
}
```

---

## Tier to Role Mapping

The system automatically maps tiers to roles:

| Backend Tier | Frontend Role | Premium |
|--------------|---------------|---------|
| `admin` | `admin` | Usually true |
| `moderator` | `moderator` | Usually true |
| `premium`, `pro`, `vip` | `player` | true |
| `free`, `basic`, `player` | `player` | false |

---

## Subscription Status Handling

Premium status can be determined by:

1. **Direct flag:** `isPremium: true`
2. **Subscription status:** `subscriptionStatus: "active"`
3. **Tier:** `tier: "premium"`

The system checks all three and sets premium to `true` if any indicate premium status.

---

## Testing Checklist

- [ ] Backend returns role in response
- [ ] Backend returns premium status in response
- [ ] AuthSession stores metadata correctly
- [ ] AuthTokenStore persists metadata to Hive
- [ ] LoginManager extracts role correctly
- [ ] LoginManager extracts premium status correctly
- [ ] ProfileService has correct role
- [ ] ProfileService has correct premium status
- [ ] SecureStorage has 'user_role' and 'is_premium'
- [ ] App restart preserves role/premium (from Hive)
- [ ] Logout clears role/premium

---

## Common Issues

### Issue 1: Role always 'player'
**Cause:** Backend not returning role field  
**Fix:** Add `"role": "admin"` to backend response

### Issue 2: Premium always false
**Cause:** Backend not returning premium status  
**Fix:** Add `"isPremium": true` to backend response

### Issue 3: Metadata not persisting
**Cause:** AuthTokenStore not updated with metadata support  
**Fix:** Replace with `auth_token_store_enhanced.dart`

### Issue 4: SignupData constructor error
**Cause:** Using `SignupData()` instead of `SignupData.fromSignupForm()`  
**Fix:** Use `auth_providers_CORRECTED.dart`

---

## Summary

✅ **Fixed:** SignupData constructor usage  
✅ **Added:** Role extraction from backend  
✅ **Added:** Premium status extraction from backend  
✅ **Added:** Metadata persistence in Hive  
✅ **Added:** Helper methods to check user status  
✅ **Supports:** Multiple role formats from backend  
✅ **Supports:** Multiple premium status indicators  
✅ **Ready for:** Admin features, premium features, role-based access control  
