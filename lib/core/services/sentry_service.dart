import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:trivia_tycoon/core/env.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

/// Service to initialize and configure Sentry for error tracking and
/// performance monitoring on Flutter clients.
class SentryService {
  /// Initialize Sentry with configuration from environment variables
  static Future<void> initialize() async {
    final dsn = _getSentryDsn();

    if (dsn == null || dsn.isEmpty) {
      LogManager.info(
        'Sentry DSN not configured - error tracking disabled',
        source: 'SentryService',
      );
      return;
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final environment = _getSentryEnvironment();
      final traceSampleRate = _getTraceSampleRate();

      await SentryFlutter.init(
        (options) {
          options.dsn = dsn;
          options.environment = environment;
          options.release = '${packageInfo.version}+${packageInfo.buildNumber}';

          // Performance monitoring
          options.tracesSampleRate = traceSampleRate;

          // Capture breadcrumbs for context
          options.maxBreadcrumbs = 200;

          // Capture failed requests
          options.captureFailedRequests = true;
          options.failedRequestStatusCodes = [
            SentryStatusCodeRange(400, 599),
          ];

          // Exclude health check and monitoring endpoints
          options.shouldLogUrl = (url) {
            return !url.contains('/health')
                && !url.contains('/metrics')
                && !url.contains('/alive')
                && !url.contains('/ready');
          };

          // Add custom tags
          options.tags = {
            'app': 'trivia-tycoon',
            'platform': defaultTargetPlatform.toString(),
            'version': packageInfo.version,
          };

          // Track user if authenticated
          options.beforeSend = (event, hint) async {
            return event;
          };
        },
      );

      LogManager.info(
        'Sentry initialized successfully (env: $environment, sampling: $traceSampleRate)',
        source: 'SentryService',
      );
    } catch (e, st) {
      LogManager.error(
        'Failed to initialize Sentry: $e',
        source: 'SentryService',
        stackTrace: st,
      );
    }
  }

  /// Get Sentry DSN from environment or return null if not configured
  static String? _getSentryDsn() {
    // Try from environment variable first
    final envDsn = EnvConfig.sentryDsn;
    if (envDsn != null && envDsn.isNotEmpty) {
      return envDsn;
    }

    // Fallback for development/testing
    if (kDebugMode) {
      return null; // Disabled in debug mode unless explicitly configured
    }

    return null;
  }

  /// Get Sentry environment (development, staging, production)
  static String _getSentryEnvironment() {
    return EnvConfig.sentryEnvironment ?? 'development';
  }

  /// Get trace sample rate (what percentage of transactions to send to Sentry)
  /// - Development: 100% (1.0) for full debugging
  /// - Production: 10% (0.1) to manage costs
  static double _getTraceSampleRate() {
    final rate = EnvConfig.sentryTraceSampleRate;
    return rate.clamp(0.0, 1.0);
  }

  /// Capture an exception with Sentry
  static Future<String?> captureException(
    dynamic exception, {
    StackTrace? stackTrace,
    String? message,
    Map<String, dynamic>? extra,
  }) async {
    try {
      return await Sentry.captureException(
        exception,
        stackTrace: stackTrace,
        withScope: (scope) {
          if (message != null) {
            scope.message = SentryMessage(message);
          }
          if (extra != null) {
            scope.setContexts('extra', extra);
          }
        },
      );
    } catch (e) {
      LogManager.error(
        'Failed to capture exception in Sentry: $e',
        source: 'SentryService',
      );
      return null;
    }
  }

  /// Add a breadcrumb for debugging
  static void addBreadcrumb({
    required String message,
    String category = 'debug',
    String level = 'info',
    Map<String, dynamic>? data,
  }) {
    try {
      Sentry.addBreadcrumb(
        SentryBreadcrumb(
          message: message,
          category: category,
          level: SentryLevel.values.byName(level),
          data: data,
        ),
      );
    } catch (e) {
      LogManager.debug('Failed to add breadcrumb: $e', source: 'SentryService');
    }
  }

  /// Set user context for error tracking
  static void setUser({
    required String id,
    String? email,
    String? username,
    Map<String, String>? extras,
  }) {
    try {
      Sentry.setUser(
        SentryUser(
          id: id,
          email: email,
          username: username,
          extras: extras,
        ),
      );
    } catch (e) {
      LogManager.debug('Failed to set user context: $e', source: 'SentryService');
    }
  }

  /// Clear user context (e.g., on logout)
  static void clearUser() {
    try {
      Sentry.setUser(null);
    } catch (e) {
      LogManager.debug('Failed to clear user: $e', source: 'SentryService');
    }
  }

  /// Set custom tag for filtering
  static void setTag(String key, String value) {
    try {
      Sentry.setTag(key, value);
    } catch (e) {
      LogManager.debug('Failed to set tag: $e', source: 'SentryService');
    }
  }

  /// Close Sentry and flush pending events
  static Future<void> close() async {
    try {
      await Sentry.close();
    } catch (e) {
      LogManager.debug('Error closing Sentry: $e', source: 'SentryService');
    }
  }
}
