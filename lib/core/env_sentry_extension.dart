import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Extension to EnvConfig for Sentry configuration
/// This keeps Sentry-specific env vars separate from the main env config
extension SentryEnvConfig on EnvConfig {
  static String? get sentryDsn {
    final dartDefined = String.fromEnvironment('SENTRY_DSN');
    return dartDefined.isNotEmpty
        ? dartDefined
        : dotenv.env['SENTRY_DSN'];
  }

  static String? get sentryEnvironment {
    final dartDefined = String.fromEnvironment('SENTRY_ENVIRONMENT');
    if (dartDefined.isNotEmpty) return dartDefined;

    return dotenv.env['SENTRY_ENVIRONMENT'] ?? 'development';
  }

  static double get sentryTraceSampleRate {
    final dartDefined = String.fromEnvironment('SENTRY_TRACE_SAMPLE_RATE');
    if (dartDefined.isNotEmpty) {
      return double.tryParse(dartDefined) ?? 1.0;
    }

    final envValue = dotenv.env['SENTRY_TRACE_SAMPLE_RATE'];
    return envValue != null
        ? (double.tryParse(envValue) ?? 1.0)
        : 1.0;
  }
}

/// Make extension methods accessible on EnvConfig class itself
abstract class EnvConfig {
  static String? get sentryDsn => SentryEnvConfig.sentryDsn;
  static String? get sentryEnvironment => SentryEnvConfig.sentryEnvironment;
  static double get sentryTraceSampleRate => SentryEnvConfig.sentryTraceSampleRate;
}
