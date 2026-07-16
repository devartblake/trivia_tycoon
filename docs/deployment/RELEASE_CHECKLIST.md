# Release Build Checklist

This document outlines all the steps required to prepare and release a production build of Synaptix for mobile, web, or desktop platforms.

---

## Pre-Build Validation

- [ ] **Update Version Numbers**
  - [ ] Update `pubspec.yaml` version (format: `x.y.z+BUILD`)
  - [ ] Update Android `android/app/build.gradle` (versionCode and versionName)
  - [ ] Update iOS `ios/Runner.xcodeproj` (version and build)
  - [ ] Update Windows `windows/runner/CMakeLists.txt`

- [ ] **Check Environment Configuration**
  - [ ] `.env.prod` file exists in `assets/config/`
  - [ ] All required environment variables are set
  - [ ] API_BASE_URL points to production: `https://api.synaptixplay.com`
  - [ ] No localhost URLs present (`localhost:`, `10.0.2.2`, `127.0.0.1`)
  - [ ] WebSocket URLs are production HTTPS (`wss://`)
  - [ ] SignalR hub URLs use production endpoints

- [ ] **Code Quality Checks**
  ```bash
  # Run static analysis
  flutter analyze
  
  # Format code
  dart format lib/
  
  # Run tests (if available)
  flutter test
  ```

- [ ] **Check for Debug/Development Code**
  ```bash
  # Automated validation
  dart scripts/validate_release_build.dart
  ```
  
  Specifically check for:
  - [ ] No `print()` or `debugPrint()` statements
  - [ ] No `kDebugMode` checks in code paths
  - [ ] No `LogManager.debug()` or `LogManager.info()` in production paths
  - [ ] No `assert()` statements in critical code
  - [ ] No TODO/FIXME/HACK comments in production code
  - [ ] No hardcoded IPs or localhost URLs
  - [ ] No development feature flags set to true

- [ ] **Verify API Endpoint Configuration**
  ```dart
  // Check that EnvConfig loads production URLs:
  // API_BASE_URL: https://api.synaptixplay.com
  // API_WS_BASE_URL: wss://api.synaptixplay.com/ws
  // API_MATCH_HUB_URL: wss://api.synaptixplay.com/ws/match
  ```

- [ ] **Disable Debug Logging**
  ```dart
  // LogManager automatically disables debug logs in release mode
  // In kReleaseMode, debug() and info() logs are suppressed
  // Only warnings and errors are printed
  ```

---

## Building Release Artifacts

### Android Release Build

```bash
# Option 1: Build APK
flutter build apk --release --target-platform android-arm64

# Option 2: Build App Bundle (recommended for Play Store)
flutter build appbundle --release
```

- [ ] Build completes without errors
- [ ] APK/AAB file size is reasonable (<150 MB)
- [ ] No warnings about development configuration

**Location**: `build/app/outputs/flutter-apk/` or `build/app/outputs/bundle/`

### iOS Release Build

```bash
# Build for iOS
flutter build ios --release

# Optional: Create .ipa for distribution
# (Usually done through Xcode or App Store Connect)
```

- [ ] Build completes without errors
- [ ] No provisioning profile issues
- [ ] No code signing warnings

**Location**: `build/ios/iphoneos/`

### Web Release Build

```bash
# Build for web
flutter build web --release
```

- [ ] Build completes without errors
- [ ] Output directory size is reasonable
- [ ] HTML/JS/CSS are minified

**Location**: `build/web/`

### Desktop Release Builds

```bash
# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release
```

---

## Post-Build Validation

```bash
# Validate the built artifact
dart scripts/validate_release_build.dart --apk build/app/outputs/flutter-apk/app-release.apk
dart scripts/validate_release_build.dart --target ios
dart scripts/validate_release_build.dart --target web
```

- [ ] No forbidden patterns detected
- [ ] No debug symbols in production code
- [ ] All checks pass

---

## Functional Testing

### On-Device Testing

- [ ] **Test on real device** (not just emulator/simulator)
  - [ ] Android: Real phone with different API levels (min 21+)
  - [ ] iOS: Real iPhone with different iOS versions (min 12+)
  - [ ] Web: Multiple browsers (Chrome, Safari, Firefox, Edge)

- [ ] **Core User Flows**
  - [ ] User can log in successfully
  - [ ] API calls use production URLs (check DevTools/Network tab)
  - [ ] WebSocket connections work correctly
  - [ ] Real-time features (leaderboard, presence) work
  - [ ] In-game transactions complete successfully
  - [ ] User profile and currency display correctly

- [ ] **Logging Behavior**
  - [ ] No DEBUG messages appear in console
  - [ ] Only ERROR/WARNING logs are visible
  - [ ] No performance degradation from logging
  - [ ] Console is clean (web DevTools inspector)

- [ ] **Network Requests**
  - [ ] All API calls go to `api.synaptixplay.com` (not localhost)
  - [ ] WebSocket connects to production (not localhost)
  - [ ] SignalR hubs use production URLs
  - [ ] No 404 or connection errors

- [ ] **Performance**
  - [ ] App launches in < 3 seconds
  - [ ] No memory leaks on extended use
  - [ ] Smooth animations throughout
  - [ ] No janky frame rates (60 fps target)

### Security Testing

- [ ] **API Communication**
  - [ ] All API calls use HTTPS
  - [ ] JWT tokens are properly sent
  - [ ] No credentials in logs or memory dumps
  - [ ] SSL certificate validation works

- [ ] **Local Storage**
  - [ ] Sensitive data is encrypted (auth tokens, etc.)
  - [ ] No plaintext passwords stored
  - [ ] Shared preferences secure

---

## Platform-Specific Checks

### Android (APK/AAB)

- [ ] [ ] Manifest has correct permissions
- [ ] [ ] Min/target SDK versions are appropriate
- [ ] [ ] Release signing certificate is configured
- [ ] [ ] No development signing

### iOS (IPA)

- [ ] [ ] Provisioning profile is release (not development)
- [ ] [ ] Code signing certificate is release
- [ ] [ ] Build number is incremented
- [ ] [ ] No development/beta entitlements

### Web

- [ ] [ ] Service Worker is configured for offline support
- [ ] [ ] Assets are cached appropriately
- [ ] [ ] No console errors on load
- [ ] [ ] Responsive design works on mobile browsers

---

## Configuration Verification

Create a test script to verify production configuration:

```bash
# After building, run this to verify:
dart scripts/validate_release_build.dart --verbose

# Check specific aspects:
grep -r "http://localhost\|10\.0\.2\.2\|127\.0\.0\.1" build/ || echo "✅ No localhost URLs"
grep -r "kDebugMode\|debugPrint\|LogManager.debug" build/flutter_assets/ || echo "✅ No debug code"
```

---

## Pre-Release Deployment

### Prepare Documentation

- [ ] Update CHANGELOG.md with all changes
- [ ] Update version in README
- [ ] Generate release notes
- [ ] Document known issues

### Create Release Branch

```bash
# Create release branch from main
git checkout -b release/v1.2.3

# Tag for reference
git tag -a v1.2.3 -m "Release version 1.2.3"
```

### Submission Checklist

**Google Play Store (Android)**
- [ ] APK/AAB file prepared
- [ ] Store listing updated
- [ ] Changelog/release notes written
- [ ] Screenshots and app icon prepared
- [ ] Privacy policy link provided
- [ ] Permissions justified

**Apple App Store (iOS)**
- [ ] IPA file prepared
- [ ] App Store listing updated
- [ ] Version/build number incremented
- [ ] Screenshots prepared
- [ ] Privacy policy compliance verified
- [ ] TestFlight build created for testing

**Web Deployment**
- [ ] Build optimized
- [ ] CNAME records configured
- [ ] SSL certificate valid
- [ ] CDN configured (if applicable)
- [ ] Analytics script configured

---

## Post-Deployment

- [ ] [ ] Monitor crash logs and error rates
- [ ] [ ] Check user feedback/reviews
- [ ] [ ] Monitor API server logs for errors
- [ ] [ ] Verify analytics are collecting data
- [ ] [ ] Set up alerts for errors/crashes
- [ ] [ ] Be ready for quick hotfix if needed

---

## Rollback Plan

If critical issues are found post-release:

1. **Immediate Actions**
   - [ ] Disable affected features if possible
   - [ ] Post-mortem message to users
   - [ ] Prepare hotfix build

2. **Hotfix Process**
   ```bash
   # Create hotfix branch
   git checkout -b hotfix/v1.2.4
   
   # Fix issue
   # Test thoroughly
   
   # Merge back to main and release
   git checkout main
   git merge hotfix/v1.2.4
   ```

3. **Resubmit to Stores**
   - [ ] New APK/AAB ready
   - [ ] Release notes mention fix
   - [ ] Version incremented

---

## Automated Build System

Use the provided build scripts for consistency:

```bash
# Linux/macOS
./scripts/build_release.sh --target all --validate

# Windows
scripts\build_release.bat --target all --validate
```

These scripts automatically:
- ✅ Run pre-build validation
- ✅ Check for development code
- ✅ Build all artifacts
- ✅ Validate built artifacts
- ✅ Provide clear error messages

---

## Environment Variables (.env.prod)

Ensure these are set for production:

```bash
# API Configuration
API_BASE_URL=https://api.synaptixplay.com
API_WS_BASE_URL=wss://api.synaptixplay.com/ws
API_HEALTH_URL=https://api.synaptixplay.com/healthz
API_MATCH_HUB_URL=wss://api.synaptixplay.com/ws/match
API_PRESENCE_HUB_URL=wss://api.synaptixplay.com/ws/presence
API_NOTIFY_HUB_URL=wss://api.synaptixplay.com/ws/notify

# Security
EXTERNAL_AUTH_PROVIDERS_ENABLED=true
CRYPTO_SURFACES_ENABLED=true
CRYPTO_WRITES_ENABLED=true

# gRPC (if using)
GRPC_HOST=api.synaptixplay.com
GRPC_PORT=5001
GRPC_USE_TLS=true

# Never include in production:
# DEBUG_LOGGING=true
# MOCK_API=true
# DEV_MODE=true
```

---

## Quick Reference Commands

```bash
# Validate source code before building
dart scripts/validate_release_build.dart

# Build all release artifacts
./scripts/build_release.sh --target all --validate

# Test locally before submission
flutter run --release

# Check for common issues
flutter analyze

# View production logs (after deployment)
flutter pub global activate crashlytics
```

---

## Support & Troubleshooting

If you encounter issues during release:

1. Check the [Flutter documentation](https://flutter.dev/docs/deployment)
2. Review CI/CD logs
3. Check app store console for specific errors
4. Consult the troubleshooting guide in `/docs`

---

**Last Updated**: June 26, 2026  
**Version**: 1.0  
**Maintained By**: Development Team
