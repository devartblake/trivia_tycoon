# App Links Deployment Guide

**Last Updated:** 2026-06-30  
**Status:** Files configured and ready for deployment

---

## Overview

This guide explains how to properly deploy the app link verification files for the Synaptix Synaptix app across web, iOS, and Android platforms.

---

## Files and Locations

### ✅ Web (.well-known directory)

**Location:** `web/.well-known/`

Files placed here will be served by the web server at:
- `https://app.synaptixgame.com/.well-known/assetlinks.json` (Android)
- `https://app.synaptixgame.com/.well-known/apple-app-site-association` (iOS)

When deploying to production, ensure your web server's root directory includes:
```
.well-known/
├── assetlinks.json
└── apple-app-site-association
```

### Android App Links

**File:** `web/.well-known/assetlinks.json`

**What it does:**
- Verifies domain ownership for Android deep linking
- Allows the app to handle URLs from `app.synaptixgame.com`
- Enables payment/subscription return flow redirection

**Required replacements before deploying:**
```json
{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.theoreticalmindstech.synaptix",
    "sha256_cert_fingerprints": [
      "YOUR_RELEASE_CERT_SHA256_FINGERPRINT"  ← REPLACE THIS
    ]
  }
}
```

**How to get the SHA-256 fingerprint:**
```bash
# For debug build
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# For release build (when ready)
keytool -list -v -keystore path/to/release.keystore -alias your_alias
```

---

### iOS App Links (Universal Links)

**File:** `web/.well-known/apple-app-site-association`

**What it does:**
- Verifies domain ownership for iOS deep linking
- Allows the app to handle URLs from `app.synaptixgame.com`
- Enables payment/subscription return flow redirection

**Required replacements before deploying:**
```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "YOUR_TEAM_ID.com.theoreticalmindstech.synaptix",  ← REPLACE THIS
        "paths": [
          "/store/payment-return",
          "/store/payment-return/*",
          "/store/subscription-return",
          "/store/subscription-return/*"
        ]
      }
    ]
  }
}
```

**How to get your Team ID:**
1. Go to [Apple Developer](https://developer.apple.com/)
2. Sign in with your Apple ID
3. Go to "Certificates, Identifiers & Profiles"
4. Your Team ID is displayed in the top-right corner

---

## Deployment Checklist

### Pre-Deployment

- [ ] Review the assetlinks.json file
- [ ] Replace `YOUR_RELEASE_CERT_SHA256_FINGERPRINT` with actual Android release certificate fingerprint
- [ ] Replace `YOUR_TEAM_ID` with actual Apple Team ID
- [ ] Get both files from `web/.well-known/`

### For Android

1. **Get Release Certificate Fingerprint:**
   - Generate your release keystore if you haven't already
   - Extract the SHA-256 fingerprint from the certificate
   - Update `assetlinks.json`

2. **Host the file:**
   - Copy `assetlinks.json` to your web server's `.well-known/` directory
   - File must be accessible at: `https://app.synaptixgame.com/.well-known/assetlinks.json`
   - Verify it's accessible: `curl https://app.synaptixgame.com/.well-known/assetlinks.json`

3. **In Android app:**
   - The `AndroidManifest.xml` already has intent filters configured
   - The `app_links` plugin is integrated
   - Perform a clean build/reinstall after publishing
   - Old APKs may need uninstalling first

### For iOS

1. **Get Team ID:**
   - Sign in to Apple Developer account
   - Copy your Team ID
   - Update `apple-app-site-association`
   - Ensure Bundle ID is `com.theoreticalmindstech.synaptix`

2. **Host the file:**
   - Copy `apple-app-site-association` to your web server's `.well-known/` directory
   - File must be accessible at: `https://app.synaptixgame.com/.well-known/apple-app-site-association`
   - OR: `https://app.synaptixgame.com/apple-app-site-association` (iOS is flexible)
   - Verify it's accessible: `curl https://app.synaptixgame.com/.well-known/apple-app-site-association`

3. **In iOS app:**
   - Associated domains entitlements already configured in Runner target
   - App supports domains: `app.synaptixgame.com`
   - Universal links will work automatically after deployment

### For Web

- The `.well-known/` directory files are automatically served by the web server
- No additional setup needed beyond standard web deployment
- Web uses the same domain and return URLs

---

## Configuration in App

The app currently expects this environment variable:

```env
APP_REDIRECT_BASE_URL=https://app.synaptixgame.com
```

This is used for:
- Building return URLs for payment/subscription flows
- Redirecting deep links back to the app
- Handling incoming links on app startup

Ensure this value is set in:
- `lib/core/env.dart` or your `.env` file
- CI/CD environment variables
- Local development `.env.local`

---

## Return URL Flows

When users complete a payment or subscription:

### Android
1. Payment processor redirects to: `https://app.synaptixgame.com/store/payment-return?...`
2. Android OS checks `assetlinks.json` to verify app ownership
3. Android opens the link in the app (not browser)
4. App router handles `/store/payment-return` route
5. Payment state updated, UI navigates to success screen

### iOS
1. Payment processor redirects to: `https://app.synaptixgame.com/store/payment-return?...`
2. iOS checks `apple-app-site-association` to verify app ownership
3. iOS opens the link in the app (not browser)
4. App router handles `/store/payment-return` route
5. Payment state updated, UI navigates to success screen

### Web
1. Payment processor redirects to: `https://app.synaptixgame.com/store/payment-return?...`
2. Web app receives the URL directly
3. App router handles `/store/payment-return` route
4. Payment state updated, UI navigates to success screen

---

## Verification & Testing

### Local Testing

For local development, you can test with:
```env
APP_REDIRECT_BASE_URL=https://localhost:3000
```

### Production Verification

After deployment, verify everything is working:

**Android:**
```bash
# Check if assetlinks.json is accessible
curl -I https://app.synaptixgame.com/.well-known/assetlinks.json
# Should return 200 OK

# Verify JSON is valid
curl https://app.synaptixgame.com/.well-known/assetlinks.json | jq .
```

**iOS:**
```bash
# Check if apple-app-site-association is accessible
curl -I https://app.synaptixgame.com/.well-known/apple-app-site-association
# Should return 200 OK

# Verify JSON is valid
curl https://app.synaptixgame.com/.well-known/apple-app-site-association | jq .
```

**On-Device Testing:**
- Uninstall old versions of the app
- Install fresh build from TestFlight (iOS) or Firebase (Android)
- Complete a payment flow to verify redirect works

---

## Troubleshooting

### "MissingPluginException" on Android
- Old APK installed before `app_links` dependency was added
- Solution: Uninstall app, do clean rebuild, reinstall

### Payment redirects to browser instead of app
- `assetlinks.json` or `apple-app-site-association` not accessible
- Verification files not updated with correct certificate/team ID
- App not reinstalled after file deployment
- Solution: Verify files are accessible, reinstall app

### Universal Links not working on iOS
- Entitlements not configured in Xcode
- Team ID doesn't match app's signing certificate
- app.synaptixgame.com domain doesn't match the app's associated domain
- Solution: Check Runner target settings, verify Team ID, check entitlements

---

## File Locations Reference

| Platform | File | Web Location | App Location |
|----------|------|--------------|--------------|
| Android  | assetlinks.json | `web/.well-known/assetlinks.json` | Served via web only |
| iOS      | apple-app-site-association | `web/.well-known/apple-app-site-association` | Served via web only |
| Web      | Both | `web/.well-known/` | Served from web root |

---

## Related Documentation

- [App Links README](./app-links/README.md) — Original deployment notes
- `lib/core/env.dart` — Environment configuration
- `android/app/src/main/AndroidManifest.xml` — Android intent filters
- `ios/Runner/Info.plist` — iOS configuration
- `lib/core/services/app_links_handler.dart` — Deep link handler (if present)

---

## Next Steps

1. ✅ Files created in `web/.well-known/`
2. ⏳ Replace placeholders (SHA-256 fingerprint and Team ID)
3. ⏳ Deploy web server to production
4. ⏳ Test on device with fresh install
5. ⏳ Monitor payment flows in production

---

**Status:** Ready for deployment  
**Created:** 2026-06-30  
**Version:** 1.0
