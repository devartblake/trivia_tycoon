# Environment Configuration Guide

This document explains how to configure the Trivia Tycoon app for different deployment environments.

## Overview

The app uses environment variables for backend API configuration. Different builds target different environments:

- **Debug builds**: Connect to local Docker backend or local development server
- **Staging builds**: Connect to staging backend for QA testing
- **Production builds**: Connect to production API for alpha/beta releases

## Environment Files

### `.env` (Debug/Default)
Used during `flutter run` (debug mode). Connects to `http://10.0.2.2:5000` (Android emulator) or `localhost:5000` (other platforms).

**Use case**: Quick local development and testing

### `.env.local` (Recommended for Docker Desktop)
Used for local development with Docker Compose backend.

**Use case**: 
- Running backend locally with Docker Compose
- Cross-platform testing (Android, iOS, Web, Desktop)
- Platform-aware host rewriting automatically handles 10.0.2.2 → localhost conversion

### `.env.staging` (Staging Environment)
Connects to staging backend for pre-release testing and QA verification.

**Use case**:
- Integration testing with staging services
- QA verification before production release
- Test premium features and third-party integrations

### `.env.prod` (Production/Alpha/Beta Release)
Connects to production API backend. Used for release builds.

**Use case**:
- Alpha/beta releases to testers
- Production deployments
- Real user testing

## How to Select Environment

### During Development (Debug Builds)

By default, `flutter run` uses `.env` or `.env.local`:

```bash
# Uses .env.local (or .env as fallback)
flutter run

# Force a specific env file via dart define
flutter run -d <device> \
  --dart-define=ENV_FILE=.env.local
```

### For Release Builds

Release builds automatically use `.env.prod`:

```bash
# Builds APK with .env.prod
flutter build apk --release

# Override with custom env file
flutter build apk --release \
  --dart-define=ENV_FILE=assets/config/.env.prod
```

### For Staging Builds

To target staging instead of production:

```bash
flutter build apk --release \
  --dart-define=ENV_FILE=assets/config/.env.staging
```

## Platform-Specific Behavior

### Android Emulator
- **10.0.2.2**: Correct loopback alias for emulator
- `http://10.0.2.2:5000` in .env files reaches host backend

### iOS Simulator / Web Browser / Desktop
- **10.0.2.2**: Not accessible (emulator-specific)
- **EnvConfig automatically rewrites**: 10.0.2.2 → localhost
- `http://10.0.2.2:5000` → `http://localhost:5000` at runtime

### Local Network (LAN) Testing
For testing on physical devices on your local network:

```env
API_BASE_URL=http://<your-machine-ip>:5000
```

EnvConfig will automatically rewrite this to your machine's IP when needed.

## Connection Verification

The app performs automatic connection checks:

1. **Health check** at startup (`/healthz` endpoint)
2. **Fallback to default**: If connection fails, uses configured fallback
3. **Logging**: Connection errors are logged in debug builds

To verify connection:

```dart
// In debug builds, check the LogManager output
// Look for: "[EnvConfig] API Base: ..."
```

## Docker Compose Setup

For local development with Docker:

```yaml
# docker-compose.yml
services:
  backend:
    image: synaptix-backend:latest
    ports:
      - "5000:5000"
      - "5001:5001"
      - "5002:5002"
    environment:
      ASPNETCORE_URLS: "http://+:5000;grpc://+:5001"
```

Then run:
```bash
docker-compose up -d
flutter run
```

## Environment Variables Reference

### API Configuration

| Variable | Format | Example |
|----------|--------|---------|
| `API_BASE_URL` | URL | `http://10.0.2.2:5000` or `https://api.example.com` |
| `API_HEALTH_PATH` | Path | `/healthz` |
| `API_WS_BASE_URL` | WSS URL | Auto-derived from API_BASE_URL if not set |
| `APP_REDIRECT_BASE_URL` | URL | `https://app.example.com` |

### gRPC Configuration

| Variable | Format | Example |
|----------|--------|---------|
| `GRPC_HOST` | Hostname | `10.0.2.2` or `api.example.com` |
| `GRPC_PORT` | Port | `5001` |
| `GRPC_USE_TLS` | Boolean | `true` or `false` |

### Timeouts (seconds)

| Variable | Default | Min |
|----------|---------|-----|
| `API_CONNECT_TIMEOUT_SECONDS` | 10 | 2 |
| `API_RECEIVE_TIMEOUT_SECONDS` | 30 | 5 |
| `API_SEND_TIMEOUT_SECONDS` | 10 | 2 |
| `API_REFRESH_RECEIVE_TIMEOUT_SECONDS` | 20 | 5 |

### Feature Flags

| Variable | Default | Purpose |
|----------|---------|---------|
| `CRYPTO_SURFACES_ENABLED` | `true` | Show wallet/staking features |
| `CRYPTO_WRITES_ENABLED` | `true` | Allow wallet mutations |
| `CRYPTO_ENABLED_NETWORKS` | `solana,xrp` | CSV of enabled networks |
| `EXTERNAL_AUTH_PROVIDERS_ENABLED` | `false` | OAuth/Game Center buttons |

### Third-Party Services

| Variable | Format | Notes |
|----------|--------|-------|
| `COMPLIANCE_SERVICE_URL` | URL | Optional; crypto disabled if not set |
| `STRIPE_PUBLISHABLE_KEY` | Key | `pk_test_...` for staging, `pk_live_...` for prod |

## Troubleshooting

### "Connection refused" on Web/iOS
**Cause**: 10.0.2.2 is not reachable from non-Android platforms

**Solution**: EnvConfig should auto-rewrite to localhost. Check logs:
```
[EnvConfig] Rewriting 10.0.2.2 → localhost (web)
```

### "Health check failed" at startup
**Cause**: Backend not running or wrong URL

**Solution**:
1. Verify backend is running: `curl http://localhost:5000/healthz`
2. Check .env file for correct URL
3. For Docker: `docker-compose logs backend`

### Wrong environment file loaded
**Cause**: Debug build accidentally using production config

**Solution**:
1. Check which file is being loaded (see logs): `[EnvConfig] Optional env file`
2. Explicitly set: `flutter run --dart-define=ENV_FILE=.env.local`
3. Clear build cache: `flutter clean`

## Security Best Practices

1. **Never commit secrets**: .env files with real API keys should not be in git
2. **Use build-time injection**: Set sensitive values via CI/CD environment variables
3. **HTTPS in production**: Always use `https://` URLs for production
4. **TLS for gRPC**: Set `GRPC_USE_TLS=true` for production
5. **Rotate tokens**: Regularly rotate API keys and signing certificates

## File Structure

```
project_root/
├── .env                    # Debug default (local testing)
├── .env.local             # Docker desktop testing (alternative)
├── .env.example           # Fallback example
├── assets/config/
│   ├── .env.prod          # Production/alpha/beta
│   ├── .env.staging       # Staging environment
│   └── release.env        # Legacy (deprecated)
└── ENV_SETUP.md          # This file
```

## Adding a New Environment

To add a new environment (e.g., `staging2`):

1. Create `assets/config/.env.staging2`
2. Configure API URLs and services
3. Build targeting that environment:
   ```bash
   flutter build apk --release --dart-define=ENV_FILE=assets/config/.env.staging2
   ```

## Related Documentation

- `lib/core/env.dart` - EnvConfig implementation
- `lib/core/bootstrap/app_init.dart` - Initialization code
- `lib/core/services/api_service.dart` - API client setup
