# Implementation Guides & How-To Documentation

Step-by-step guides for implementing features, fixing bugs, and best practices.

## 📋 Files

- **CONSOLE_CLEANUP_FIXES.md** - Guide for reducing console noise and debug output
- **PRODUCTION_BUILD_GUIDE.md** - Checklist and best practices for production builds
- **FIXES_APPLIED.md** - Summary of bugs fixed, issues resolved, and solutions

## 🎯 Common Tasks

### Reducing Console Noise
**Reference:** CONSOLE_CLEANUP_FIXES.md

```dart
// ✅ DO: Use conditional logging
if (kDebugMode) {
  LogManager.debug('Debug message');
}

// ❌ DON'T: Log everything always
LogManager.debug('This prints every time');
```

### Building for Production
**Reference:** PRODUCTION_BUILD_GUIDE.md

Before building:
1. Check all API endpoints use production URLs
2. Verify no hardcoded credentials
3. Disable debug logging flags
4. Run release build validation
5. Test on target platform

### Applying Bug Fixes
**Reference:** FIXES_APPLIED.md

When implementing a fix:
1. Document the issue and root cause
2. Implement the fix with type safety
3. Add comprehensive logging
4. Test both happy and error paths
5. Update FIXES_APPLIED.md with summary

## 🔨 Implementation Patterns

### Error Handling
```dart
try {
  // Implementation
  LogManager.debug('[Component] Operation started');
  // ... do work ...
  LogManager.debug('[Component] Operation completed');
} catch (e) {
  LogManager.error(
    '[Component] Error: $e',
    source: 'Component.method',
    error: e,
  );
  rethrow;
}
```

### Logging Best Practices
- Use `[ComponentName]` prefix for all logs
- Log entry and exit points
- Log important state changes
- Make debug logs conditional (kDebugMode)
- Avoid logging sensitive data (passwords, tokens)

### Testing After Changes
1. Verify change compiles
2. Test happy path functionality
3. Test error conditions
4. Check for regressions
5. Verify console output is clean

---

**Last Updated:** June 27, 2026
