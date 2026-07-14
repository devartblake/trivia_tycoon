# Build and Deployment Guide

This document explains how to build and deploy Synaptix for different environments with proper secret injection.

## Overview

The app supports multiple deployment scenarios:
- **Debug builds**: Connect to local development backend
- **Alpha/Beta releases**: Connect to production API with test credentials
- **Production**: Connect to production API with production credentials
- **Staging**: Connect to staging API for QA testing

All sensitive secrets are **injected at build time** via `--dart-define` flags. They are NOT stored in version control.

## Prerequisites

- Flutter SDK (latest stable)
- Android NDK/SDK (for Android builds)
- Xcode (for iOS builds)
- Git for version control

## Environment Configuration

### Development (Debug Builds)

For local testing with Docker:

```bash
flutter run
# or explicitly:
flutter run -d android --dart-define=ENV_FILE=.env.local
```

**Uses**: `.env.local` (connects to http://10.0.2.2:5000)

### Staging Builds

For QA testing against staging backend:

```bash
flutter build apk --release \
  --dart-define=ENV_FILE=assets/config/.env.staging \
  --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_YOUR_STRIPE_KEY
```

**Uses**: `assets/config/.env.staging` (connects to https://staging-api.synaptixplay.com)

### Production / Alpha / Beta Builds

For production releases with real backend:

```bash
flutter build apk --release \
  --dart-define=ENV_FILE=assets/config/.env.prod \
  --dart-define=API_BASE_URL=https://api.synaptixplay.com \
  --dart-define=STRIPE_PUBLISHABLE_KEY=pk_live_YOUR_STRIPE_KEY \
  --dart-define=COMPLIANCE_SERVICE_URL=https://compliance.synaptixplay.com
```

**Uses**: `assets/config/.env.prod` (connects to https://api.synaptixplay.com)

## Secrets Injection

Sensitive configuration values should be injected at build time, not stored in version control.

### Method 1: Command-Line Dart Defines (Simple)

Good for CI/CD pipelines:

```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://your-api.com \
  --dart-define=STRIPE_PUBLISHABLE_KEY=pk_live_ABC123 \
  --dart-define=GRPC_HOST=api.example.com
```

**Pros**: Simple, all configuration in one command, easy to script

**Cons**: Long command lines, requires careful escaping

### Method 2: Environment Variables + Scripts (Recommended)

Create a build script that reads from environment variables:

#### `scripts/build_prod.sh`

```bash
#!/bin/bash
set -e

# Read secrets from environment variables
API_BASE_URL="${SYNAPTIX_API_URL}"
STRIPE_KEY="${SYNAPTIX_STRIPE_KEY}"
COMPLIANCE_URL="${SYNAPTIX_COMPLIANCE_URL}"

# Validate required variables
if [ -z "$API_BASE_URL" ]; then
  echo "Error: SYNAPTIX_API_URL not set"
  exit 1
fi

# Build with secrets injected
flutter build apk --release \
  --dart-define=ENV_FILE=assets/config/.env.prod \
  --dart-define=API_BASE_URL="$API_BASE_URL" \
  --dart-define=STRIPE_PUBLISHABLE_KEY="$STRIPE_KEY" \
  --dart-define=COMPLIANCE_SERVICE_URL="$COMPLIANCE_URL" \
  --dart-define=GRPC_USE_TLS=true
```

Usage:

```bash
export SYNAPTIX_API_URL=https://api.example.com
export SYNAPTIX_STRIPE_KEY=pk_live_YOUR_KEY
export SYNAPTIX_COMPLIANCE_URL=https://compliance.example.com

./scripts/build_prod.sh
```

### Method 3: GitHub Actions Workflow (Best for CI/CD)

Create `.github/workflows/release.yml`:

```yaml
name: Build Release APK

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: 'latest'
      
      - name: Get dependencies
        run: flutter pub get
      
      - name: Build Release APK
        env:
          API_BASE_URL: ${{ secrets.PROD_API_URL }}
          STRIPE_KEY: ${{ secrets.PROD_STRIPE_KEY }}
          COMPLIANCE_URL: ${{ secrets.PROD_COMPLIANCE_URL }}
        run: |
          flutter build apk --release \
            --dart-define=ENV_FILE=assets/config/.env.prod \
            --dart-define=API_BASE_URL="$API_BASE_URL" \
            --dart-define=STRIPE_PUBLISHABLE_KEY="$STRIPE_KEY" \
            --dart-define=COMPLIANCE_SERVICE_URL="$COMPLIANCE_URL" \
            --dart-define=GRPC_USE_TLS=true
      
      - name: Upload to Google Play
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.PLAY_STORE_SERVICE_ACCOUNT }}
          packageName: com.synaptixplay.synaptix
          releaseFiles: build/app/outputs/apk/release/app-release.apk
          track: beta
```

**Setup GitHub Secrets**:
1. Go to: Settings → Secrets and variables → Actions
2. Add secrets:
   - `PROD_API_URL`: https://api.synaptixplay.com
   - `PROD_STRIPE_KEY`: pk_live_YOUR_KEY
   - `PROD_COMPLIANCE_URL`: https://compliance.synaptixplay.com
   - `PLAY_STORE_SERVICE_ACCOUNT`: (JSON from Google Play)

## Platform-Specific Builds

### Android (APK/AAB)

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release \
  --dart-define=ENV_FILE=assets/config/.env.prod \
  --dart-define=API_BASE_URL=https://your-api.com

# Release App Bundle (for Play Store)
flutter build appbundle --release \
  --dart-define=ENV_FILE=assets/config/.env.prod \
  --dart-define=API_BASE_URL=https://your-api.com
```

**Output**: `build/app/outputs/apk/release/app-release.apk`

### iOS

```bash
# Debug build
flutter build ios --debug

# Release build
flutter build ios --release \
  --dart-define=ENV_FILE=assets/config/.env.prod \
  --dart-define=API_BASE_URL=https://your-api.com
```

**Output**: `build/ios/iphoneos/Runner.app`

### Web

```bash
# Debug build
flutter build web

# Release build
flutter build web --release \
  --dart-define=ENV_FILE=assets/config/.env.prod \
  --dart-define=API_BASE_URL=https://your-api.com
```

**Output**: `build/web/`

## Dart Define Variables Reference

### Required for All Builds

| Variable | Example | Notes |
|----------|---------|-------|
| `ENV_FILE` | `assets/config/.env.prod` | Environment file to load |
| `API_BASE_URL` | `https://api.example.com` | Backend API base URL |

### Required for Production

| Variable | Example | Notes |
|----------|---------|-------|
| `STRIPE_PUBLISHABLE_KEY` | `pk_live_ABC123` | Stripe public key |
| `COMPLIANCE_SERVICE_URL` | `https://compliance.example.com` | Compliance service URL |
| `GRPC_USE_TLS` | `true` | Use TLS for gRPC |

### Optional

| Variable | Example | Default |
|----------|---------|---------|
| `GRPC_HOST` | `api.example.com` | Derived from API_BASE_URL |
| `GRPC_PORT` | `5001` | 5001 |
| `CRYPTO_SURFACES_ENABLED` | `true` | true |
| `CRYPTO_WRITES_ENABLED` | `true` | true |
| `EXTERNAL_AUTH_PROVIDERS_ENABLED` | `false` | false |

## Security Checklist

Before releasing to production:

- [ ] API URLs use HTTPS (not HTTP)
- [ ] gRPC uses TLS (`GRPC_USE_TLS=true`)
- [ ] Stripe key is `pk_live_*` (not `pk_test_*`)
- [ ] Compliance service URL is configured
- [ ] External auth providers are disabled until configured
- [ ] No secrets stored in version control
- [ ] CI/CD uses GitHub Secrets for sensitive values
- [ ] Environment files in `assets/config/` are included in release builds
- [ ] Logging is set to Warning level (not Debug)
- [ ] EXTERNAL_AUTH_PROVIDERS_ENABLED is false (unless configured)

## Verification

### Test the Build

1. **Verify connection at startup**:
   ```
   [EnvConfig] API Base: https://api.synaptixplay.com
   [EnvConfig] Health check: https://api.synaptixplay.com/healthz
   [EnvConfig] WebSocket: wss://api.synaptixplay.com/ws
   ```

2. **Check gRPC configuration**:
   ```
   [EnvConfig] gRPC: api.synaptixplay.com:5001 (TLS)
   ```

3. **Verify health check succeeds**:
   - App should display dashboard without connection errors
   - Network calls should succeed

### Test on Actual Devices

1. **Android Emulator**: Tests platform-aware host rewriting
2. **Physical Android Device**: Tests real network conditions
3. **iOS Simulator**: Tests web-like host rewriting
4. **Web Browser**: Tests CORS and WebSocket handling

### Monitor Logs

```bash
# View app logs
flutter logs

# Filter for connection issues
flutter logs | grep -i "env\|health\|connection\|error"
```

## Troubleshooting

### "Connection refused" on Release Build

**Cause**: Wrong API URL or backend not running

**Solution**:
```bash
# Verify the URL works:
curl -v https://your-api.com/healthz

# Rebuild with explicit URL:
flutter build apk --release \
  --dart-define=API_BASE_URL=https://your-correct-api.com
```

### "TLS certificate verification failed"

**Cause**: Self-signed cert or MITM proxy blocking connection

**Solution**:
- For production: Ensure valid certificate from trusted CA
- For development: Use HTTP locally, not HTTPS
- Check `GRPC_USE_TLS` setting matches backend configuration

### Stripe Integration Not Working

**Cause**: Wrong Stripe key or missing configuration

**Solution**:
- Use `pk_live_*` for production, `pk_test_*` for staging
- Verify key matches your Stripe account
- Check Stripe dashboard for webhook configuration

### Environment File Not Found

**Cause**: Incorrect ENV_FILE path or file not in pubspec.yaml

**Solution**:
1. Verify file exists in `assets/config/`
2. Check `pubspec.yaml` includes the file:
   ```yaml
   assets:
     - assets/config/.env.prod
     - assets/config/.env.staging
   ```
3. Run: `flutter pub get`

## Deployment Pipeline Example

### Full Release Workflow

```bash
#!/bin/bash
set -e

VERSION="${1:-1.0.0}"
echo "Building Synaptix v$VERSION for production..."

# Validate environment
if [ -z "$PROD_API_URL" ]; then
  echo "Error: PROD_API_URL not set"
  exit 1
fi

# Clean previous builds
flutter clean
flutter pub get

# Run tests
flutter test

# Build APK
flutter build apk --release \
  --dart-define=ENV_FILE=assets/config/.env.prod \
  --dart-define=API_BASE_URL="$PROD_API_URL" \
  --dart-define=STRIPE_PUBLISHABLE_KEY="$PROD_STRIPE_KEY" \
  --dart-define=COMPLIANCE_SERVICE_URL="$PROD_COMPLIANCE_URL" \
  --dart-define=GRPC_USE_TLS=true

# Build AAB for Play Store
flutter build appbundle --release \
  --dart-define=ENV_FILE=assets/config/.env.prod \
  --dart-define=API_BASE_URL="$PROD_API_URL" \
  --dart-define=STRIPE_PUBLISHABLE_KEY="$PROD_STRIPE_KEY" \
  --dart-define=COMPLIANCE_SERVICE_URL="$PROD_COMPLIANCE_URL" \
  --dart-define=GRPC_USE_TLS=true

echo "✓ APK: build/app/outputs/apk/release/app-release.apk"
echo "✓ AAB: build/app/outputs/bundle/release/app-release.aab"
echo "Ready for upload to Google Play!"
```

## Related Documentation

- `ENV_SETUP.md` - Environment configuration reference
- `lib/core/env.dart` - EnvConfig implementation
- `pubspec.yaml` - Asset configuration
- `.env`, `.env.local`, `.env.prod`, `.env.staging` - Environment files
