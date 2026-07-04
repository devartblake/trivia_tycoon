import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

/// Service to initialize and configure Sentry for error tracking and
/// performance monitoring on Flutter clients.
class SentryService {
  /// Get Sentry DSN from environment
  static String? getSentryDsn() {
    final dartDefined = String.fromEnvironment('SENTRY_DSN');
    if (dartDefined.isNotEmpty) return dartDefined;
    return dotenv.env['SENTRY_DSN'];
  }

  /// Get Sentry environment (development, staging, production)
  static String getSentryEnvironment() {
    final dartDefined = String.fromEnvironment('SENTRY_ENVIRONMENT');
    if (dartDefined.isNotEmpty) return dartDefined;
    return dotenv.env['SENTRY_ENVIRONMENT'] ?? 'development';
  }

  /// Get trace sample rate (what percentage of transactions to send to Sentry)
  static double getTraceSampleRate() {
    final dartDefined = String.fromEnvironment('SENTRY_TRACE_SAMPLE_RATE');
    double rate = 1.0;

    if (dartDefined.isNotEmpty) {
      rate = double.tryParse(dartDefined) ?? 1.0;
    } else {
      final envValue = dotenv.env['SENTRY_TRACE_SAMPLE_RATE'];
      rate = envValue != null ? (double.tryParse(envValue) ?? 1.0) : 1.0;
    }

    return rate.clamp(0.0, 1.0);
  }

  /// Initialize Sentry with configuration from environment variables
  static Future<void> initialize() async {
    final dsn = getSentryDsn();

    if (dsn == null || dsn.isEmpty) {
      LogManager.info(
        'Sentry DSN not configured - error tracking disabled',
        source: 'SentryService',
      );
      return;
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final environment = getSentryEnvironment();
      final traceSampleRate = getTraceSampleRate();

      await SentryFlutter.init(
        (options) {
          options.dsn = dsn;
          options.environment = environment;
          options.release = '${packageInfo.version}+${packageInfo.buildNumber}';
          options.tracesSampleRate = traceSampleRate;
          options.maxBreadcrumbs = 200;
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

  /// Capture an exception with Sentry
  static Future<void> captureException(
    dynamic exception, {
    StackTrace? stackTrace,
  }) async {
    try {
      await Sentry.captureException(exception, stackTrace: stackTrace);
    } catch (e) {
      LogManager.error(
        'Failed to capture exception in Sentry: $e',
        source: 'SentryService',
      );
    }
  }

  /// Add a breadcrumb for debugging
  static void addBreadcrumb({
    required String message,
    String category = 'debug',
    Map<String, dynamic>? data,
  }) {
    try {
      Sentry.addBreadcrumb(
        Breadcrumb(
          message: message,
          category: category,
          data: data,
        ),
      );
    } catch (e) {
      LogManager.debug('Failed to add breadcrumb: $e', source: 'SentryService');
    }
  }

  /// Set user context for error tracking via scope
  static Future<void> setUser({
    required String id,
    String? email,
    String? username,
  }) async {
    try {
      await Sentry.configureScope((scope) {
        scope.user = SentryUser(
          id: id,
          email: email,
          username: username,
        );
      });
    } catch (e) {
      LogManager.debug('Failed to set user context: $e', source: 'SentryService');
    }
  }

  /// Clear user context (e.g., on logout)
  static Future<void> clearUser() async {
    try {
      await Sentry.configureScope((scope) {
        scope.user = null;
      });
    } catch (e) {
      LogManager.debug('Failed to clear user: $e', source: 'SentryService');
    }
  }

  /// Set custom tag via scope
  static Future<void> setTag(String key, String value) async {
    try {
      await Sentry.configureScope((scope) {
        scope.setTag(key, value);
      });
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
