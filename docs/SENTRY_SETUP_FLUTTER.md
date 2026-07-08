# Sentry Error Tracking for Trivia Tycoon Flutter Client

**Status:** ✅ Implemented & active in the default entrypoint (`lib/main.dart`)  
**Updated:** 2026-07-08 — Sentry init was merged into `lib/main.dart`; `main_with_sentry.dart` was removed. All builds get Sentry automatically when a DSN is configured. A `SentryNavigatorObserver` is attached to the app router for screen breadcrumbs.  
**Implementation Date:** 2026-07-03  
**Version:** 1.0

---

## Overview

Sentry integration has been added to the Trivia Tycoon Flutter client for centralized error tracking, performance monitoring, and crash reporting.

### Features

✅ Automatic exception capture  
✅ Performance monitoring (transaction tracing)  
✅ Breadcrumb tracking for debugging context  
✅ Configurable sampling rates by environment (dev 100%, staging 50%, prod 10%)  
✅ Release tracking (version + build number)  
✅ Graceful fallback when DSN not configured  

---

## Quick Start

### 1. Install Dependencies

The `sentry_flutter` package has been added to `pubspec.yaml`. Run:

```bash
flutter pub get
```

### 2. Environment Configuration

Choose the right `.env` file for your build:

**Development** (default):
```bash
flutter run                    # Uses .env
flutter run -d chrome         # Web development
```

**Staging**:
```bash
flutter run --dart-define-from-file=.env.staging
```

**Production**:
```bash
flutter run --dart-define-from-file=.env.prod
```

### 3. Add Sentry DSN

Create a Sentry project at https://sentry.io and get your DSN:

**Development** (`.env`):
```bash
SENTRY_DSN=                          # Leave empty to disable in dev
SENTRY_ENVIRONMENT=development
SENTRY_TRACE_SAMPLE_RATE=1.0         # 100% sampling in development
```

**Staging** (`.env.staging`):
```bash
SENTRY_DSN=https://xxx@domain.ingest.sentry.io/project-id
SENTRY_ENVIRONMENT=staging
SENTRY_TRACE_SAMPLE_RATE=0.5         # 50% sampling in staging
```

**Production** (`.env.prod`):
```bash
SENTRY_DSN=https://xxx@domain.ingest.sentry.io/project-id
SENTRY_ENVIRONMENT=production
SENTRY_TRACE_SAMPLE_RATE=0.1         # 10% sampling in production (cost control)
```

### 4. Run the App

Sentry initializes automatically from the default entrypoint whenever a DSN
is configured — no special target is needed:

```bash
flutter run
```

With no `SENTRY_DSN` set, the app runs exactly as before with error
tracking disabled.

---

## Configuration Details

### Environment Variables

| Variable | Purpose | Default | Dev | Staging | Prod |
|----------|---------|---------|-----|---------|------|
| `SENTRY_DSN` | Sentry project ID | empty | empty | staging-id | prod-id |
| `SENTRY_ENVIRONMENT` | Environment label | dev | dev | staging | prod |
| `SENTRY_TRACE_SAMPLE_RATE` | % of traces to send | 1.0 | 1.0 | 0.5 | 0.1 |

### Sample Rates Explained

**Development (1.0 = 100%)**
- Captures every trace and error
- Best for debugging and development
- No cost implications

**Staging (0.5 = 50%)**
- Captures half of transactions
- Balances visibility and cost
- Good for pre-production testing

**Production (0.1 = 10%)**
- Captures 10% of transactions
- Minimizes Sentry quota usage
- Reduces costs while maintaining visibility

---

## Using Sentry in Your Code

### Automatic Capture

Unhandled exceptions and crashes are automatically captured:

```dart
// These are captured automatically
throw Exception('Something went wrong');
```

### Manual Exception Capture

```dart
import 'package:trivia_tycoon/core/services/sentry_service.dart';

try {
  // Some code
} catch (e, st) {
  await SentryService.captureException(e, stackTrace: st);
}
```

### Add Breadcrumbs

Breadcrumbs create a trail of events leading up to an error:

```dart
SentryService.addBreadcrumb(
  message: 'Loaded user profile',
  category: 'user-action',
  data: {'userId': userId},
);

SentryService.addBreadcrumb(
  message: 'Quiz started',
  category: 'game',
  data: {'quizId': quizId, 'difficulty': difficulty},
);

// If an error occurs now, both breadcrumbs appear in Sentry
```

---

## Sentry Dashboard

### Accessing Sentry

1. Go to https://sentry.io
2. Select your project (trivia-tycoon)
3. View issues, performance, and releases

### Key Sections

**Issues**
- All captured exceptions grouped by type
- Stack traces and breadcrumbs
- User who experienced it
- Device/platform information

**Performance**
- Transaction times (P50, P90, P99)
- Slowest endpoints/screens
- Performance trends over time
- Affected users

**Releases**
- Version tracking
- Release health
- Regression detection
- Issues per release

**Alerts**
- Slack notifications for new issues
- High error rate alerts
- Performance degradation alerts

---

## Integration Points

### App Initialization

`lib/main.dart` handles initialization:

```dart
// Automatically runs at app start
await SentryService.initialize();
```

### Error Handling in Services

Wrap critical operations:

```dart
// In any service
try {
  final result = await performCriticalOperation();
} catch (e, st) {
  await SentryService.captureException(e, stackTrace: st);
  rethrow; // Let app handle the error
}
```

### Network Errors

Failed API requests are automatically captured if status code is 400-599:

```dart
// Automatic capture for failed HTTP requests
final response = await apiClient.get('/endpoint');
// 500 errors captured in Sentry automatically
```

### Crash Recovery

Integrates with existing `CrashRecoveryService`:

```dart
// After Sentry captures the crash, recovery service restores state
final recovery = await crashRecoveryService.restore(persistenceService);
```

---

## Testing

### Test Sentry Locally

Add a test button to your debug menu:

```dart
ElevatedButton(
  onPressed: () {
    // This will appear in Sentry
    throw Exception('Test Sentry integration');
  },
  child: Text('Test Sentry'),
)
```

Then:
1. Run the app in debug mode: `flutter run`
2. Tap the test button to trigger an exception
3. Check Sentry dashboard within 30 seconds
4. Verify error appears in the Sentry Issues list

### Disable for Testing

To disable Sentry for unit tests:

```dart
// In test file
setUpAll(() {
  // Sentry won't capture in test environment
  // when SENTRY_DSN is empty
});
```

---

## Best Practices

### 1. Add Breadcrumbs for Important Actions

```dart
// Before each user action
SentryService.addBreadcrumb(
  message: 'User started quiz',
  category: 'user-interaction',
  data: {'quizId': quizId, 'difficulty': difficulty},
);
```

### 2. Capture Exceptions with Context

```dart
try {
  await performCriticalOperation();
} catch (e, st) {
  // Breadcrumbs before the error are automatically included
  await SentryService.captureException(e, stackTrace: st);
}
```

### 3. Don't Over-Sample Production

```bash
# Production should be 0.1 or lower
SENTRY_TRACE_SAMPLE_RATE=0.1
```

### 4. Monitor Performance

Use Sentry's performance tab to identify slow screens:
- Quiz loading time
- Leaderboard queries
- Match initialization
- Payment processing

### 5. Add Initialization Breadcrumbs

`lib/main.dart` automatically adds breadcrumbs during app initialization:
```dart
SentryService.addBreadcrumb(
  message: 'App initialization completed',
  category: 'app-lifecycle',
  data: {
    'isLoggedIn': isLoggedIn.toString(),
    'ageGroup': savedAgeGroup,
    'mode': initialMode.name,
  },
);
```

---

## Common Issues

### Sentry Not Capturing Errors

1. Verify DSN is set and not empty:
   ```bash
   flutter run --dart-define-from-file=.env.staging
   # Check app console output
   ```

2. Check environment file has a valid SENTRY_DSN:
   ```bash
   cat .env.staging | grep SENTRY_DSN
   # Should show: SENTRY_DSN=https://xxx@domain.ingest.sentry.io/project-id
   ```

3. View Sentry initialization logs:
   ```bash
   flutter run --dart-define-from-file=.env.staging -v 2>&1 | grep -i sentry
   ```

### No Data in Sentry

1. Ensure the app is built with the correct entry point:
   ```bash
   flutter run  # lib/main.dart initializes Sentry when a DSN is set
   ```
2. Trigger a test error (see Testing section)
3. Wait 30 seconds for events to appear in Sentry dashboard
4. Check Sentry dashboard filter (environment, release, sampling)
5. Verify sample rate is > 0 in `.env` file

### High Sentry Costs

**Reduce sample rates:**
```bash
# Too high - costs money
SENTRY_TRACE_SAMPLE_RATE=1.0

# Better - 10% in production
SENTRY_TRACE_SAMPLE_RATE=0.1
```

### Sensitive Data in Sentry

Sentry automatically redacts:
- Passwords
- API keys
- Credit card numbers
- Tokens

Custom redaction in `sentry_service.dart`:

```dart
options.beforeSend = (event, hint) async {
  // Remove sensitive data from event
  // Return null to drop the event entirely
  return event;
};
```

---

## Alerts and Notifications

### Setup Slack Alerts

1. Go to Sentry project settings
2. Click **Integrations**
3. Search for **Slack**
4. Click **Add Workspace**
5. Authorize Sentry for your Slack workspace
6. Choose channels for notifications

### Alert Rules

Create custom rules for:
- New issues
- High error rate (> 5% of sessions)
- Crash rate spike
- Performance regression

---

## Release Tracking

### Tag Releases

Update `lib/main.dart` with version:

```dart
options.release = '${packageInfo.version}+${packageInfo.buildNumber}';
```

This automatically associates errors with releases:
- Which version introduced a bug
- When was it fixed
- Performance per version

---

## Privacy and Compliance

### Data Retention

Default: 30 days  
Adjustable in Sentry project settings

### GDPR Compliance

- User PII is minimized (just ID and email)
- No request/response bodies captured
- Automatic redaction of sensitive data

### Data Deletion

Users can request data deletion:
```dart
// Clear user data on logout
SentryService.clearUser();
```

---

## Resources

- [Sentry Flutter Documentation](https://docs.sentry.io/platforms/flutter/)
- [Performance Monitoring](https://docs.sentry.io/product/performance/)
- [Breadcrumbs Guide](https://docs.sentry.io/product/error-reporting/breadcrumbs/)
- [Release Tracking](https://docs.sentry.io/product/releases/)
- [Sentry Pricing](https://sentry.io/pricing/)

---

## Next Steps

1. ✅ Sentry package added to pubspec.yaml
2. ✅ Environment configuration files created
3. ✅ SentryService implemented with core APIs
4. ✅ Sentry initialization active in lib/main.dart (default entrypoint)
5. → Test locally: `flutter run --dart-define-from-file=.env.staging`
6. → Create Sentry projects for staging/prod at https://sentry.io
7. → Add DSN values to `.env.staging` and `.env.prod`
8. → Test error capture by triggering an exception
9. → Integrate Slack alerts in Sentry dashboard
10. → Monitor issues in Sentry and verify sampling rates

---

**Status:** Ready for local testing  
**Last Updated:** 2026-07-04  
**Maintained By:** Mobile Team
