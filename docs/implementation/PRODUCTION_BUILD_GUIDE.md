# Production Build Guide

Complete guide for building, validating, and deploying Synaptix to production.

---

## Overview

This guide covers:
1. ✅ Cleaning up DEBUG logging for production
2. ✅ Verifying all API endpoints use production URLs
3. ✅ Validating no development code exists in release builds
4. ✅ Automated build process with validation

---

## Quick Start

### For Impatient Devs (5 minutes)

```bash
# 1. Build and validate in one command
./scripts/build_release.sh --target all --validate

# OR on Windows:
scripts\build_release.bat --target all --validate

# That's it! ✅
```

### For Thorough Devs (30 minutes)

1. Read the [Release Checklist](../RELEASE_CHECKLIST.md)
2. Run the validation script
3. Test on real devices
4. Deploy to app stores

---

## What Changed: Debug Logging

### Before (Noisy Console)

```
2026-06-26 12:02:54 [DEBUG] 🐛 [Lifecycle] 📱 App RESUMED
2026-06-26 12:02:54 [DEBUG] 🐛 [WebSocket] WebSocket not available
2026-06-26 12:02:55 [DEBUG] 🐛 [Leaderboard] Using WebSocket mode
2026-06-26 12:02:57 [DEBUG] 🐛 [Leaderboard] Loaded 0 entries from API
```

### After (Clean Console)

```
✅ Only errors and warnings shown
⚠️ No info or debug logs cluttering the output
```

### How It Works

The `LogManager` class now:
- Automatically enables production mode in `kReleaseMode`
- Suppresses `debug()` and `info()` logs
- Only shows `warning()` and `error()` logs
- Can be manually controlled via `LogManager.setProductionMode(bool)`

```dart
// In release mode, this is automatic:
if (LogManager.isProductionMode) {
  // debug() logs are skipped
  // info() logs are skipped
  // warning() and error() are shown
}
```

---

## What Changed: API Endpoints

### Automatic Environment Switching

The `EnvConfig` class already handles this intelligently:

```dart
// lib/core/env.dart
// Automatically selects based on build mode:
// - Release mode: assets/config/.env.prod
// - Debug mode: .env.local (with fallback to .env)

static Future<void> load() async {
  final envFile = kReleaseMode
      ? 'assets/config/.env.prod'  // ← Production URLs
      : '.env.local';                // ← Local dev URLs
  
  await dotenv.load(fileName: envFile, isOptional: true);
}
```

### Production URLs

`assets/config/.env.prod`:
```bash
# Production configuration
API_BASE_URL=https://api.synaptixplay.com
API_WS_BASE_URL=wss://api.synaptixplay.com/ws
API_MATCH_HUB_URL=wss://api.synaptixplay.com/ws/match
API_PRESENCE_HUB_URL=wss://api.synaptixplay.com/ws/presence
API_NOTIFY_HUB_URL=wss://api.synaptixplay.com/ws/notify

# These are automatically loaded in release builds
# No manual configuration needed!
```

### Verification

Check which endpoints will be used:

```bash
# Before building, validate endpoints
dart scripts/validate_release_build.dart

# Output:
# ✅ No localhost URLs found
# ✅ No hardcoded IPs found
# ✅ All API endpoints verified
```

---

## New Build Tools

### 1. Release Build Validator (Dart)

**File**: `scripts/validate_release_build.dart`

**Purpose**: Scans source code for development artifacts

**Usage**:
```bash
# Validate source code
dart scripts/validate_release_build.dart

# Validate built APK
dart scripts/validate_release_build.dart --apk path/to/app.apk

# Validate specific target
dart scripts/validate_release_build.dart --target ios

# Verbose output
dart scripts/validate_release_build.dart --verbose
```

**Checks for**:
- ❌ localhost URLs
- ❌ Debug print statements
- ❌ kDebugMode checks
- ❌ LogManager.debug() calls
- ❌ Assert statements
- ❌ TODO/FIXME comments
- ❌ Hardcoded IPs

### 2. Build Release Script (Linux/macOS)

**File**: `scripts/build_release.sh`

**Purpose**: Automates build process with validation

**Usage**:
```bash
# Build all targets with validation
./scripts/build_release.sh --target all --validate

# Build specific target
./scripts/build_release.sh --target android --validate

# Clean and rebuild
./scripts/build_release.sh --target ios --clean

# Skip validation (not recommended)
./scripts/build_release.sh --target web
```

### 3. Build Release Script (Windows)

**File**: `scripts/build_release.bat`

**Purpose**: Windows equivalent of build script

**Usage**:
```batch
# Build all targets with validation
scripts\build_release.bat --target all --validate

# Build specific target
scripts\build_release.bat --target android --validate
```

---

## Release Build Flow

```
┌─────────────────────────────────┐
│ 1. Pre-Build Validation         │
│  - Check environment config     │
│  - Scan source code             │
│  - Validate no debug code       │
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│ 2. Build Release Artifact       │
│  - flutter build apk --release  │
│  - flutter build ios --release  │
│  - flutter build web --release  │
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│ 3. Post-Build Validation        │
│  - Scan built binary            │
│  - Verify no localhost URLs     │
│  - Check file sizes             │
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│ 4. Test on Real Device          │
│  - Functional testing           │
│  - Check console logs           │
│  - Verify API endpoints         │
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│ 5. Deploy to App Stores         │
│  - Google Play Store            │
│  - Apple App Store              │
│  - Web hosting                  │
└─────────────────────────────────┘
```

---

## Step-by-Step Release Process

### Step 1: Prepare (15 min)

```bash
# Update version
# Edit pubspec.yaml: version: 1.2.3+BUILD_NUMBER

# Commit changes
git add -A
git commit -m "Release v1.2.3"

# Tag release
git tag v1.2.3
```

### Step 2: Validate (5 min)

```bash
# Run validation script
dart scripts/validate_release_build.dart

# Expected output:
# ✅ All checks passed!
# ✅ No forbidden patterns detected
```

### Step 3: Build (10-30 min, depending on targets)

```bash
# Option A: Automated (recommended)
./scripts/build_release.sh --target all --validate

# Option B: Manual
flutter build apk --release
flutter build ios --release
flutter build web --release

# Then validate each:
dart scripts/validate_release_build.dart --apk build/app/outputs/flutter-apk/app-release.apk
```

### Step 4: Test (30 min - 1 hour)

```bash
# Install on device
flutter install --release

# Or test APK:
adb install build/app/outputs/flutter-apk/app-release.apk

# Functional testing:
# ✅ Login works
# ✅ API calls reach production
# ✅ No debug logs in console
# ✅ WebSocket connects
# ✅ Real-time features work
```

### Step 5: Deploy

**Android**:
```bash
# Create AAB for Play Store
flutter build appbundle --release

# Submit to Google Play Console
# - Upload AAB file
# - Update release notes
# - Set rollout percentage
```

**iOS**:
```bash
# Build for App Store
flutter build ios --release

# Use Xcode or App Store Connect to submit
# - Configure signing
# - Submit for review
```

**Web**:
```bash
# Deploy built web app
# Location: build/web/

# Options:
# - Deploy to Firebase Hosting
# - Deploy to custom server
# - Deploy to CDN
```

---

## Environment Configuration

### For Development

**File**: `.env.local` or `.env`

```bash
API_BASE_URL=http://10.0.2.2:5000
API_WS_BASE_URL=ws://10.0.2.2:5000/ws
API_MATCH_HUB_URL=ws://10.0.2.2:5000/ws/match
API_PRESENCE_HUB_URL=ws://10.0.2.2:5000/ws/presence
API_NOTIFY_HUB_URL=ws://10.0.2.2:5000/ws/notify
```

### For Production

**File**: `assets/config/.env.prod`

```bash
API_BASE_URL=https://api.synaptixplay.com
API_WS_BASE_URL=wss://api.synaptixplay.com/ws
API_MATCH_HUB_URL=wss://api.synaptixplay.com/ws/match
API_PRESENCE_HUB_URL=wss://api.synaptixplay.com/ws/presence
API_NOTIFY_HUB_URL=wss://api.synaptixplay.com/ws/notify
EXTERNAL_AUTH_PROVIDERS_ENABLED=true
CRYPTO_SURFACES_ENABLED=true
CRYPTO_WRITES_ENABLED=true
```

### For Staging (Optional)

**File**: `assets/config/.env.staging`

```bash
API_BASE_URL=https://staging-api.synaptixplay.com
# ... other staging URLs
```

---

## Verification Checklist

Before submitting to app stores:

- [ ] No DEBUG logs in console
- [ ] All API calls go to production
- [ ] WebSocket uses `wss://` (not `ws://`)
- [ ] HTTPS certificate is valid
- [ ] Login works end-to-end
- [ ] Real-time features (leaderboard, chat) work
- [ ] In-app purchases work (if applicable)
- [ ] Performance is acceptable
- [ ] No memory leaks
- [ ] Crashes are zero

**Run this command to verify everything**:

```bash
dart scripts/validate_release_build.dart --verbose
```

---

## Troubleshooting

### "Still seeing DEBUG logs in release build"

**Solution**:
```bash
# Make sure you're running release mode
flutter run --release  # NOT just 'flutter run'

# Or verify build mode:
flutter build apk --release  # Explicitly specify release
```

### "API calls going to localhost"

**Solution**:
```bash
# Check .env.prod exists:
ls assets/config/.env.prod

# Verify content:
cat assets/config/.env.prod
# Should show: API_BASE_URL=https://api.synaptixplay.com

# Rebuild:
flutter build <platform> --release
```

### "WebSocket connection failed"

**Solution**:
```bash
# Check WebSocket URLs in .env.prod
# Should use wss:// (secure WebSocket over HTTPS)

# Check firewall isn't blocking port 443
# Verify SSL certificate is valid

# Test connectivity:
curl -v https://api.synaptixplay.com/healthz
```

### "Build validation fails with warnings"

**Solution**:
```bash
# Review the warnings:
dart scripts/validate_release_build.dart --verbose

# Fix any development code that made it into release build
# Common issues:
# - LogManager.debug() calls (should be removed or wrapped in kDebugMode)
# - print() or debugPrint() (remove these)
# - assert() statements (remove for production)
# - TODO comments (resolve before release)

# Rebuild and test:
./scripts/build_release.sh --target all --validate
```

---

## Performance Tips

1. **Reduce App Size**
   - Use `--split-per-abi` for Android
   - Enable ProGuard for Android
   - Use `--obfuscate` for iOS

2. **Optimize for Speed**
   - Remove debug symbols
   - Enable R8 shrinking
   - Lazy-load heavy components

3. **Monitor**
   - Set up Crashlytics
   - Configure analytics
   - Monitor API response times

---

## Next Steps

1. **First time releasing?**
   - Read [RELEASE_CHECKLIST.md](../RELEASE_CHECKLIST.md)
   - Understand each step

2. **Ready to build?**
   - Run: `./scripts/build_release.sh --target all --validate`
   - Test on real devices
   - Submit to stores

3. **Need help?**
   - Check [API_ENDPOINTS_VERIFICATION.md](./API_ENDPOINTS_VERIFICATION.md)
   - Review [RELEASE_CHECKLIST.md](../RELEASE_CHECKLIST.md)
   - Debug using validation script

---

## Summary of Changes

| Aspect | Change | Benefit |
|--------|--------|---------|
| **Debug Logging** | Automatic suppression in release | Clean production console |
| **API Endpoints** | Environment-based config | No hardcoded URLs |
| **Validation** | Automated script | Catch issues before release |
| **Build Process** | Scripted with validation | Consistent, reliable builds |
| **Documentation** | Comprehensive guides | Clear release process |

---

**Last Updated**: June 26, 2026  
**Version**: 1.0  
**Maintained By**: Development Team
