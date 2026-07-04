# Sentry Error Tracking for Trivia Tycoon Flutter Client

**Status:** ✅ Implemented  
**Implementation Date:** 2026-07-03  
**Version:** 1.0

---

## Overview

Sentry integration has been added to the Trivia Tycoon Flutter client for centralized error tracking, performance monitoring, and crash reporting.

### Features

✅ Automatic exception capture  
✅ Performance monitoring (transaction tracing)  
✅ Breadcrumb tracking for debugging context  
✅ User identification and tracking  
✅ Configurable sampling rates by environment  
✅ Custom tags and context  
✅ Failed request tracking  
✅ Release tracking  

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

### 4. Switch to New Main Entry Point

Two main entry points are available:

**Original** (no Sentry):
```bash
# lib/main.dart
flutter run
```

**With Sentry** (recommended):
```dart
// lib/main_with_sentry.dart
flutter run -t lib/main_with_sentry.dart
```

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
  await SentryService.captureException(
    e,
    stackTrace: st,
    message: 'User action failed',
    extra: {
      'userId': userId,
      'action': 'leaderboard_submit',
      'score': finalScore,
    },
  );
}
```

### Add Breadcrumbs

Breadcrumbs create a trail of events leading up to an error:

```dart
SentryService.addBreadcrumb(
  message: 'Loaded user profile',
  category: 'user-action',
  level: 'info',
  data: {'userId': userId},
);

SentryService.addBreadcrumb(
  message: 'Quiz started',
  category: 'game',
  level: 'info',
  data: {'quizId': quizId, 'difficulty': difficulty},
);

// If an error occurs now, both breadcrumbs appear in Sentry
```

### Set User Context

Track which user encountered the error:

```dart
// After login
SentryService.setUser(
  id: userId,
  email: userEmail,
  username: playerName,
  extras: {
    'age_group': ageGroup,
    'synaptix_mode': mode,
    'premium': isPremium.toString(),
  },
);

// After logout
SentryService.clearUser();
```

### Add Custom Tags

Tags help filter and search issues in Sentry:

```dart
SentryService.setTag('quiz_mode', 'multiplayer');
SentryService.setTag('game_type', 'battle-royale');
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

The new `main_with_sentry.dart` already handles initialization:

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
    // This will appear in Sentry with 'test' tag
    SentryService.setTag('test', 'manual');
    throw Exception('Test Sentry integration');
  },
  child: Text('Test Sentry'),
)
```

Then:
1. Run the app in debug mode
2. Tap the test button
3. Check Sentry dashboard within 30 seconds
4. Verify error appears with test tag

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

### 1. Set User Context Early

After user logs in:
```dart
SentryService.setUser(
  id: userId,
  email: userEmail,
  username: playerName,
);
```

### 2. Add Breadcrumbs for Important Actions

```dart
// Before each user action
SentryService.addBreadcrumb(
  message: 'User tapped submit button',
  category: 'user-interaction',
);
```

### 3. Use Extra Data for Context

```dart
await SentryService.captureException(
  error,
  extra: {
    'screen': 'quiz-detail',
    'quizId': quizId,
    'timeSpent': duration.inSeconds,
  },
);
```

### 4. Don't Over-Sample Production

```bash
# Production should be 0.1 or lower
SENTRY_TRACE_SAMPLE_RATE=0.1
```

### 5. Clean Up on Logout

```dart
SentryService.clearUser();
```

### 6. Monitor Performance

Use Sentry's performance tab to identify slow screens:
- Quiz loading time
- Leaderboard queries
- Match initialization
- Payment processing

---

## Common Issues

### Sentry Not Capturing Errors

1. Verify DSN is set:
   ```bash
   echo $SENTRY_DSN
   ```

2. Check environment file:
   ```bash
   cat .env | grep SENTRY
   ```

3. View logs:
   ```bash
   flutter run -v 2>&1 | grep -i sentry
   ```

### No Data in Sentry

1. Ensure the app is built with the correct .env file
2. Wait 30 seconds for events to appear
3. Check Sentry dashboard filter (environment, release)
4. Verify sample rate is > 0

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

Update `main_with_sentry.dart` with version:

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
3. ✅ SentryService implemented
4. → Create Sentry projects for dev/staging/prod
5. → Add DSN to environment files
6. → Test with main_with_sentry.dart
7. → Integrate Slack alerts
8. → Monitor issues in Sentry dashboard

---

**Status:** Ready for integration  
**Last Updated:** 2026-07-03  
**Maintained By:** Mobile Team
