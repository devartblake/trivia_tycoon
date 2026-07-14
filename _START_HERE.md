# Synaptix - Start Here 🚀

> **Current status (2026-07-08):** For the up-to-date project state, read
> [docs/MASTER_TASK_TRACKING.md](docs/MASTER_TASK_TRACKING.md) and the
> [Codebase Audit & 5-Sprint Plan](docs/audit/CODEBASE_AUDIT_AND_SPRINT_PLAN_2026_07_08.md).
> Sprint 1 (critical fixes: question reachability, Sentry, Friends routing) landed 2026-07-08 —
> see [CHANGELOG.md](CHANGELOG.md) 4.2.0. **Toolchain: Flutter ≥ 3.44.5 required.**
> The document below describes the earlier widget-modularization/CI session and remains valid.

Welcome! This document guides you through the major architectural improvements completed in this session.

## What Changed?

### 1. Widget Architecture
The massive `synaptix_dashboard_widgets.dart` file (1900 lines) has been refactored into **31 focused files** organized by responsibility.

**Result**: Code that's easier to test, maintain, and develop in parallel.

👉 **Learn more**: [Widget Structure](lib/features/synaptix_home/widgets/)

### 2. Environment Management
Multi-environment configuration system for debug, staging, and production.

**Result**: Seamless switching between local, staging, and production APIs.

👉 **Learn more**: [ENV_SETUP.md](ENV_SETUP.md)

### 3. Automated Deployments
GitHub Actions CI/CD pipeline that builds and deploys automatically.

**Result**: One command (`git tag v1.0.0`) triggers full build, test, and Play Store upload.

👉 **Learn more**: [BUILD_AND_DEPLOY.md](BUILD_AND_DEPLOY.md)

---

## Quick Start

### For Developers
```bash
# Clone the repo
git clone https://github.com/your-org/trivia-tycoon.git
cd trivia-tycoon

# Run debug build (connects to local Docker backend)
flutter run

# Or test against staging
flutter run --dart-define=ENV_FILE=assets/config/.env.staging
```

### For Release Engineers
```bash
# 1. Setup GitHub Secrets (see GITHUB_SECRETS_SETUP.md)
# 2. Create a version tag
git tag v1.0.0
git push origin v1.0.0

# CI/CD automatically:
# - Runs tests
# - Builds APK/AAB
# - Uploads to Google Play
# - Notifies Slack
```

### For QA Teams
```bash
# Build staging APK for manual testing
flutter build apk --release \
  --dart-define=ENV_FILE=assets/config/.env.staging

# Install on device
adb install -r build/app/outputs/apk/release/app-release.apk

# Verify backend connection
flutter logs | grep -i "env\|health"
```

---

## Documentation Roadmap

Start with the document that matches your role/task:

### 🎯 Overview
- **[MODULARIZATION_AND_DEPLOYMENT.md](MODULARIZATION_AND_DEPLOYMENT.md)** - Complete summary of all changes (30 min read)

### 💻 Development
- **[ENV_SETUP.md](ENV_SETUP.md)** - How environments work and how to configure them locally
- **[CONNECTION_TESTING.md](CONNECTION_TESTING.md)** - Verifying backend connections across platforms

### 🚀 Releases
- **[BUILD_AND_DEPLOY.md](BUILD_AND_DEPLOY.md)** - How to build for different environments
- **[GITHUB_SECRETS_SETUP.md](GITHUB_SECRETS_SETUP.md)** - Setting up CI/CD secrets for automated builds

### 📋 Reference
- **[.github/workflows/release.yml](.github/workflows/release.yml)** - Automated build workflow
- **[lib/features/synaptix_home/widgets/](lib/features/synaptix_home/widgets/)** - Modularized widget files

---

## The Problem We Solved

### Before
```
❌ 1900-line widget file
❌ 39 widgets tangled together
❌ Difficult to test individual widgets
❌ Manual builds and deployments
❌ No environment separation
```

### After
```
✅ 31 focused files (single responsibility each)
✅ Clear dependency graph
✅ Easy to test and parallelize development
✅ Automated builds via GitHub Actions
✅ Seamless environment switching
```

---

## Key Features

### Modular Widget Architecture
- **Layout**: Panel, footer, row components
- **Navigation**: Top bar, drawer, rail, logo
- **Cards**: Hero tournament, game modes, profiles, missions, etc.
- **Sidebar**: Menu, rank, streak, referral
- **Components**: Reusable progress bars, headers

**Benefit**: Each file is ~50-200 lines instead of 1900

### Multi-Environment Support
```bash
# Debug (local Docker)
flutter run

# Staging (staging API)
flutter run --dart-define=ENV_FILE=assets/config/.env.staging

# Production (live API)
git tag v1.0.0  # Triggers CI/CD automatically
```

**Benefit**: No code changes needed to target different backends

### Automated CI/CD Pipeline
```
git tag v1.0.0
    ↓
GitHub Actions runs automatically
    ↓
Tests run, code analyzed
    ↓
APK and App Bundle built
    ↓
Uploaded to Google Play (beta track)
    ↓
Slack notification sent
    ↓
Done!
```

**Benefit**: No manual build steps, consistent deployments, audit trail

---

## Environment Configuration

### Local Development
```env
# .env.local
API_BASE_URL=http://10.0.2.2:5000
# EnvConfig automatically rewrites to localhost for non-Android
```

### Staging
```env
# assets/config/.env.staging
API_BASE_URL=https://staging-api.synaptixplay.com
STRIPE_PUBLISHABLE_KEY=pk_test_*
```

### Production
```env
# assets/config/.env.prod
API_BASE_URL=https://api.synaptixplay.com
STRIPE_PUBLISHABLE_KEY=pk_live_*
# (injected at build time via GitHub Secrets)
```

---

## GitHub Secrets Required

Before first production release, set up these GitHub Secrets:

```
PROD_API_URL                - Production API endpoint
PROD_STRIPE_KEY             - Stripe live publishable key
PROD_COMPLIANCE_URL         - Compliance service
STAGING_API_URL             - Staging API endpoint
STAGING_STRIPE_KEY          - Stripe test key
STAGING_COMPLIANCE_URL      - Staging compliance service
ANDROID_KEYSTORE_BASE64     - Base64-encoded keystore
ANDROID_KEY_PROPERTIES      - Keystore passwords
PLAY_STORE_SERVICE_ACCOUNT  - Google Play API JSON
SLACK_WEBHOOK_URL           - Optional: Slack notifications
```

👉 **Setup guide**: [GITHUB_SECRETS_SETUP.md](GITHUB_SECRETS_SETUP.md)

---

## Git Commits This Session

```
6e0ba3f Add comprehensive summary
a0eb9f2 Complete CI/CD setup with production build pipeline
cd5e800 Complete widget modularization: 1900-line monolith to 31 focused files
cdca3a4 Set up production/staging/dev environment configuration
142795f Revert FriendsOnlineCard from rail
```

---

## Common Tasks

### Run debug build locally
```bash
flutter run
```

### Build staging release
```bash
flutter build apk --release \
  --dart-define=ENV_FILE=assets/config/.env.staging
```

### Create production release
```bash
git tag v1.0.0
git push origin v1.0.0
# CI/CD handles everything automatically
```

### Test backend connection
```bash
# See connection testing guide
cat CONNECTION_TESTING.md | less
```

### Setup GitHub Secrets
```bash
# Follow the setup guide
cat GITHUB_SECRETS_SETUP.md | less
```

---

## FAQ

**Q: How do I connect to a different backend?**
A: Change the API_BASE_URL in the environment file (.env, .env.local, .env.staging, or .env.prod)

**Q: How do I test locally without Docker?**
A: Set API_BASE_URL=http://localhost:5000 in .env.local and run your backend manually

**Q: How are secrets stored?**
A: GitHub Secrets - encrypted, never logged, only visible to repo maintainers

**Q: How do production releases work?**
A: Push a git tag → GitHub Actions builds → uploaded to Play Store automatically

**Q: Can I test the CI/CD workflow without tagging?**
A: Yes, use manual workflow dispatch from GitHub Actions tab

**Q: What if a build fails?**
A: Check GitHub Actions logs, Slack notification shows failure, fix the issue, re-tag

---

## Need Help?

- **Widget architecture**: Read widget file comments or check MODULARIZATION_AND_DEPLOYMENT.md
- **Environment setup**: See ENV_SETUP.md
- **Building for release**: See BUILD_AND_DEPLOY.md
- **GitHub Secrets**: See GITHUB_SECRETS_SETUP.md
- **Testing connections**: See CONNECTION_TESTING.md

---

## You're Ready!

Everything is set up for development, testing, and production releases.

**Next step**: Read MODULARIZATION_AND_DEPLOYMENT.md for comprehensive overview.

Happy coding! 💻
