import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

/// A class to manage and provide environment variables from a .env file.
/// This ensures that sensitive keys and configuration-specific URLs are not
/// hardcoded in the application source code.
class EnvConfig {
  static const _releaseApiBaseUrlFallback = 'https://api.synaptixplay.com';
  static const _debugApiBaseUrlFallback = 'http://10.0.2.2:5000';

  /// API Base URL
  static String? _apiBaseUrl = '';

  /// WebSocket Base URL
  static String? _apiWsBaseUrl = '';

  /// SignalR hub URLs
  static String? _matchHubUrl;
  static String? _presenceHubUrl;
  static String? _notifyHubUrl;
  static String? _appRedirectBaseUrl;
  static String? _apiHealthUrl;
  static bool _cryptoSurfacesEnabled = true;
  static bool _cryptoWritesEnabled = true;
  static Set<String> _enabledCryptoNetworks = const {'solana', 'xrp'};
  static String? _complianceServiceUrl;
  static String? _complianceConsentServiceUrl;
  static String? _stripePublishableKey;
  static Duration _apiConnectTimeout = const Duration(seconds: 10);
  static Duration _apiReceiveTimeout = const Duration(seconds: 30);
  static Duration _apiSendTimeout = const Duration(seconds: 10);
  static Duration _apiRefreshReceiveTimeout = const Duration(seconds: 20);

  /// Getter for the backend API Base URL (bare host, no version prefix).
  /// Use this for non-versioned surfaces: WebSocket/health URLs, gRPC host
  /// derivation, asset resolution.
  static String get apiBaseUrl {
    assert(_apiBaseUrl != null, 'API_BASE_URL is not loaded from .env');
    return _apiBaseUrl!;
  }

  /// Base URL for the versioned public REST API. The backend serves every
  /// public client endpoint under /api/v1 (single source of truth), so every
  /// REST client that talks to a feature/auth endpoint must build on this.
  static String get apiV1BaseUrl => '$apiBaseUrl/api/v1';

  static Duration get apiConnectTimeout => _apiConnectTimeout;
  static Duration get apiReceiveTimeout => _apiReceiveTimeout;
  static Duration get apiSendTimeout => _apiSendTimeout;
  static Duration get apiRefreshReceiveTimeout => _apiRefreshReceiveTimeout;

  /// Getter for the backend WebSocket base URL.
  static String get apiWsBaseUrl {
    assert(_apiWsBaseUrl != null, 'API_WS_BASE_URL is not loaded from .env');
    return _apiWsBaseUrl!;
  }

  /// Getter for the SignalR Match hub URL.
  static String get matchHubUrl {
    assert(_matchHubUrl != null, 'API_MATCH_HUB_URL is not loaded from .env');
    return _matchHubUrl!;
  }

  /// Getter for the SignalR Presence hub URL.
  static String get presenceHubUrl {
    assert(_presenceHubUrl != null,
        'API_PRESENCE_HUB_URL is not loaded from .env');
    return _presenceHubUrl!;
  }

  /// Getter for the SignalR Notification hub URL.
  static String get notifyHubUrl {
    assert(_notifyHubUrl != null, 'API_NOTIFY_HUB_URL is not loaded from .env');
    return _notifyHubUrl!;
  }

  /// Optional frontend/app base URL for payment return routing.
  static String? get appRedirectBaseUrl => _appRedirectBaseUrl;

  /// Public backend health endpoint used by startup readiness checks.
  static String get apiHealthUrl {
    assert(_apiHealthUrl != null, 'API_HEALTH_URL is not loaded from .env');
    return _apiHealthUrl!;
  }

  // ── gRPC configuration ────────────────────────────────────────────────────

  /// Host for the backend gRPC service (MobileMatchService, port 5001).
  /// Defaults to the same host as [apiBaseUrl] when not set.
  static String get grpcHost {
    const dartDefined = String.fromEnvironment('GRPC_HOST');
    final configured =
        dartDefined.isNotEmpty ? dartDefined : dotenv.env['GRPC_HOST'];
    if (configured != null && configured.isNotEmpty) return configured;
    // Fall back to the API host (strip scheme and port).
    return Uri.tryParse(_apiBaseUrl ?? '')?.host ?? 'localhost';
  }

  /// Port for the backend gRPC service (default: 5001).
  static int get grpcPort {
    const dartDefined = String.fromEnvironment('GRPC_PORT');
    final raw = dartDefined.isNotEmpty ? dartDefined : dotenv.env['GRPC_PORT'];
    if (raw != null && raw.isNotEmpty) {
      return int.tryParse(raw) ?? 5001;
    }
    return 5001;
  }

  /// Whether to use TLS for the gRPC channel.
  /// Defaults to false for local dev; set GRPC_USE_TLS=true for staging/prod.
  static bool get grpcUseTls {
    const dartDefined = String.fromEnvironment('GRPC_USE_TLS');
    final raw =
        (dartDefined.isNotEmpty ? dartDefined : dotenv.env['GRPC_USE_TLS'])
            ?.toLowerCase();
    return raw == 'true' || raw == '1';
  }

  /// Whether native game-platform (Game Center / Play Games) and OAuth/social
  /// sign-in are exposed in the UI.
  ///
  /// Defaults to false: the backend registers these routes but returns 501
  /// until provider credentials and server-side signature/token verification
  /// are wired. Keeping the buttons hidden stops Alpha testers from hitting a
  /// dead end. Set EXTERNAL_AUTH_PROVIDERS_ENABLED=true once verification is
  /// configured on the server.
  static bool get externalAuthProvidersEnabled {
    const dartDefined =
        String.fromEnvironment('EXTERNAL_AUTH_PROVIDERS_ENABLED');
    final raw = (dartDefined.isNotEmpty
            ? dartDefined
            : dotenv.env['EXTERNAL_AUTH_PROVIDERS_ENABLED'])
        ?.toLowerCase();
    return raw == 'true' || raw == '1';
  }

  /// Base URL of the compliance microservice (optional; crypto + prize gates are disabled when absent).
  static String? get complianceServiceUrl => _complianceServiceUrl;

  /// Base URL of the Synaptix.Compliance.Api service (age verification, consent,
  /// parental consent, privacy requests). These routes live at `/compliance/...`,
  /// so when no dedicated URL is configured we default to the main API host.
  static String get complianceConsentServiceUrl =>
      _complianceConsentServiceUrl ?? apiBaseUrl;

  /// Stripe Identity publishable key exposed to the Flutter client.
  static String? get stripePublishableKey => _stripePublishableKey;

  /// Enables player-facing crypto wallet surfaces.
  static bool get cryptoSurfacesEnabled => _cryptoSurfacesEnabled;

  /// Enables mutating crypto actions such as link wallet, withdraw, stake,
  /// unstake, and prize-pool funding. Read-only crypto surfaces may remain
  /// visible while writes are disabled.
  static bool get cryptoWritesEnabled => _cryptoWritesEnabled;

  /// Network keys enabled for frontend selection.
  static Set<String> get enabledCryptoNetworks =>
      Set.unmodifiable(_enabledCryptoNetworks);

  static String _joinWsPath(String baseUrl, String suffixPath) {
    final baseUri = Uri.parse(baseUrl);
    final baseSegments =
        baseUri.pathSegments.where((s) => s.isNotEmpty).toList();
    final suffixSegments =
        Uri.parse(suffixPath).pathSegments.where((s) => s.isNotEmpty).toList();

    final mergedSegments = <String>[...baseSegments];
    if (mergedSegments.isNotEmpty &&
        suffixSegments.isNotEmpty &&
        mergedSegments.last == suffixSegments.first) {
      mergedSegments.addAll(suffixSegments.skip(1));
    } else {
      mergedSegments.addAll(suffixSegments);
    }

    return baseUri.replace(pathSegments: mergedSegments).toString();
  }

  static String _resolveApiHealthUrl({
    required String apiBaseUrl,
    String? configuredHealthUrl,
    String? configuredHealthPath,
  }) {
    final healthUrl = configuredHealthUrl?.trim();
    if (healthUrl != null && healthUrl.isNotEmpty) {
      return _normalizeApiBaseUrlForRuntime(healthUrl);
    }

    final healthPath = configuredHealthPath?.trim();
    final path =
        healthPath == null || healthPath.isEmpty ? '/healthz' : healthPath;

    final parsedPath = Uri.tryParse(path);
    if (parsedPath != null && parsedPath.hasScheme) {
      return _normalizeApiBaseUrlForRuntime(path);
    }

    return _joinWsPath(apiBaseUrl, path);
  }

  static String _normalizeApiBaseUrlForRuntime(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return trimmed;

    Uri parsed = Uri.parse(trimmed);

    // ── 1. Downgrade https → http for well-known local dev addresses.
    // Local dev backends almost never have valid SSL certs, so https:// to
    // localhost / 10.0.2.2 / 127.0.0.1 fails with a handshake error on every
    // platform. Convert silently so a .env typo doesn't block development.
    //
    // Debug builds only: in profile/release we must NEVER rewrite the scheme.
    // A misconfigured staging URL (e.g. API_BASE_URL=http(s)://localhost:5000,
    // a tunnelled staging box, or a forwarded port) would otherwise send
    // cleartext auth traffic while appearing to have TLS. Fail loud on a bad
    // cert instead, so the misconfig is caught before tokens cross the wire.
    const localHosts = {'localhost', '10.0.2.2', '127.0.0.1'};
    if (kDebugMode &&
        parsed.scheme == 'https' &&
        localHosts.contains(parsed.host)) {
      LogManager.debug(
        '[EnvConfig] Downgrading https→http for local dev address: $trimmed',
      );
      parsed = parsed.replace(scheme: 'http');
    }

    // ── 2. Platform-aware host rewriting for 10.0.2.2 (Android emulator loopback).
    // • Web (Edge / Chrome): browsers cannot reach 10.0.2.2 — rewrite to localhost.
    // • Android native emulator: 10.0.2.2 is exactly right — leave it alone.
    // • iOS simulator / macOS / desktop: 10.0.2.2 is unreachable — rewrite to localhost.
    if (!kReleaseMode && parsed.host == '10.0.2.2') {
      if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
        final normalized = parsed.replace(host: 'localhost').toString();
        LogManager.debug(
          '[EnvConfig] Rewriting 10.0.2.2 → localhost '
          '(${kIsWeb ? "web" : defaultTargetPlatform.name}): $trimmed -> $normalized',
        );
        return normalized;
      }
      // Android emulator: 10.0.2.2 is the correct host — no change needed.
      return parsed.toString();
    }

    // ── 3. Android emulator reverse mapping (localhost → 10.0.2.2).
    // On Android emulators, localhost / 127.0.0.1 resolves to the emulator
    // itself, not the host machine running the dev server. Rewrite local API
    // URLs so Android emulator builds can still reach the host backend.
    if (!kReleaseMode &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        (parsed.host == 'localhost' || parsed.host == '127.0.0.1')) {
      final normalized = parsed.replace(host: '10.0.2.2').toString();
      LogManager.debug(
        '[EnvConfig] Rewriting localhost → 10.0.2.2 for Android emulator: '
        '$trimmed -> $normalized',
      );
      return normalized;
    }

    return parsed.toString();
  }

  static bool _loaded = false;

  /// Loads all environment variables from the .env file into memory.
  /// This must be called once during app initialization before any services
  /// that rely on these variables are created. Safe to call multiple times —
  /// subsequent calls are no-ops.
  ///
  /// Environment file selection (in order of precedence):
  /// 1. ENV_FILE dart environment variable (if set)
  /// 2. Release mode: assets/config/.env.prod (production)
  /// 3. Debug mode: .env.local (local Docker), falls back to .env
  ///
  /// File locations:
  /// - .env / .env.local: Local development with Docker
  /// - .env.prod: Production/alpha/beta release (in assets/config/)
  /// - .env.staging: Staging environment (in assets/config/)
  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    const dartDefinedEnvFile = String.fromEnvironment('ENV_FILE');
    final envFile = dartDefinedEnvFile.isNotEmpty
        ? dartDefinedEnvFile
        : kReleaseMode
            ? 'assets/config/.env.prod'
            : '.env.local';
    try {
      await dotenv.load(fileName: envFile, isOptional: true);
    } catch (e) {
      LogManager.debug(
        '[EnvConfig] Optional env file "$envFile" was not loaded: $e',
      );
      // Ensure dotenv is initialized so downstream dotenv.get() calls
      // return their fallback values instead of throwing NotInitializedError.
      dotenv.loadFromString(isOptional: true);
    }

    try {
      // Load variables from the environment
      const dartDefinedApiBaseUrl = String.fromEnvironment('API_BASE_URL');
      const dartDefinedApiHealthUrl = String.fromEnvironment('API_HEALTH_URL');
      const dartDefinedApiHealthPath =
          String.fromEnvironment('API_HEALTH_PATH');
      const dartDefinedApiWsBaseUrl = String.fromEnvironment('API_WS_BASE_URL');
      const dartDefinedMatchHubUrl =
          String.fromEnvironment('API_MATCH_HUB_URL');
      const dartDefinedPresenceHubUrl =
          String.fromEnvironment('API_PRESENCE_HUB_URL');
      const dartDefinedNotifyHubUrl =
          String.fromEnvironment('API_NOTIFY_HUB_URL');
      const dartDefinedCryptoSurfacesEnabled =
          String.fromEnvironment('CRYPTO_SURFACES_ENABLED');
      const dartDefinedCryptoWritesEnabled =
          String.fromEnvironment('CRYPTO_WRITES_ENABLED');
      const dartDefinedCryptoEnabledNetworks =
          String.fromEnvironment('CRYPTO_ENABLED_NETWORKS');
      const dartDefinedComplianceServiceUrl =
          String.fromEnvironment('COMPLIANCE_SERVICE_URL');
      const dartDefinedStripePublishableKey =
          String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');

      final rawApiBaseUrl = dartDefinedApiBaseUrl.isNotEmpty
          ? dartDefinedApiBaseUrl
          : dotenv.get(
              'API_BASE_URL',
              fallback: kReleaseMode
                  ? _releaseApiBaseUrlFallback
                  : _debugApiBaseUrlFallback,
            );
      _apiBaseUrl = _normalizeApiBaseUrlForRuntime(rawApiBaseUrl);
      _apiHealthUrl = _resolveApiHealthUrl(
        apiBaseUrl: apiBaseUrl,
        configuredHealthUrl: dartDefinedApiHealthUrl.isNotEmpty
            ? dartDefinedApiHealthUrl
            : dotenv.env['API_HEALTH_URL'],
        configuredHealthPath: dartDefinedApiHealthPath.isNotEmpty
            ? dartDefinedApiHealthPath
            : dotenv.env['API_HEALTH_PATH'],
      );

      // Derive WebSocket URL from HTTP URL
      // Convert http:// to ws:// and https:// to wss://
      _apiWsBaseUrl = dartDefinedApiWsBaseUrl.isNotEmpty
          ? _normalizeApiBaseUrlForRuntime(dartDefinedApiWsBaseUrl)
          : '${apiBaseUrl.replaceFirst('http://', 'ws://').replaceFirst('https://', 'wss://')}/ws';

      LogManager.debug('[EnvConfig] API Base: $apiBaseUrl');
      LogManager.debug('[EnvConfig] API Health: $apiHealthUrl');
      LogManager.debug('[EnvConfig] WebSocket: $apiWsBaseUrl');

      _matchHubUrl = dartDefinedMatchHubUrl.isNotEmpty
          ? _normalizeApiBaseUrlForRuntime(dartDefinedMatchHubUrl)
          : dotenv.env['API_MATCH_HUB_URL'] ??
              (_apiWsBaseUrl == null
                  ? null
                  : _joinWsPath(_apiWsBaseUrl!, '/ws/match'));
      _presenceHubUrl = dartDefinedPresenceHubUrl.isNotEmpty
          ? _normalizeApiBaseUrlForRuntime(dartDefinedPresenceHubUrl)
          : dotenv.env['API_PRESENCE_HUB_URL'] ??
              (_apiWsBaseUrl == null
                  ? null
                  : _joinWsPath(_apiWsBaseUrl!, '/ws/presence'));
      _notifyHubUrl = dartDefinedNotifyHubUrl.isNotEmpty
          ? _normalizeApiBaseUrlForRuntime(dartDefinedNotifyHubUrl)
          : dotenv.env['API_NOTIFY_HUB_URL'] ??
              (_apiWsBaseUrl == null
                  ? null
                  : _joinWsPath(_apiWsBaseUrl!, '/ws/notify'));
      _appRedirectBaseUrl = _resolveAppRedirectBaseUrl();
      _cryptoSurfacesEnabled = _parseBool(
        dartDefinedCryptoSurfacesEnabled.isNotEmpty
            ? dartDefinedCryptoSurfacesEnabled
            : dotenv.env['CRYPTO_SURFACES_ENABLED'],
        fallback: true,
      );
      _cryptoWritesEnabled = _parseBool(
        dartDefinedCryptoWritesEnabled.isNotEmpty
            ? dartDefinedCryptoWritesEnabled
            : dotenv.env['CRYPTO_WRITES_ENABLED'],
        fallback: true,
      );
      _enabledCryptoNetworks = _parseCsvSet(
        dartDefinedCryptoEnabledNetworks.isNotEmpty
            ? dartDefinedCryptoEnabledNetworks
            : dotenv.env['CRYPTO_ENABLED_NETWORKS'],
        fallback: const {'solana', 'xrp'},
      );
      final rawComplianceServiceUrl = dartDefinedComplianceServiceUrl.isNotEmpty
          ? dartDefinedComplianceServiceUrl
          : dotenv.env['COMPLIANCE_SERVICE_URL'];
      _complianceServiceUrl = rawComplianceServiceUrl == null
          ? null
          : _normalizeApiBaseUrlForRuntime(rawComplianceServiceUrl.trim());
      const dartDefinedComplianceConsentUrl =
          String.fromEnvironment('COMPLIANCE_CONSENT_SERVICE_URL');
      final rawComplianceConsentUrl = dartDefinedComplianceConsentUrl.isNotEmpty
          ? dartDefinedComplianceConsentUrl
          : dotenv.env['COMPLIANCE_CONSENT_SERVICE_URL'];
      _complianceConsentServiceUrl = rawComplianceConsentUrl == null ||
              rawComplianceConsentUrl.trim().isEmpty
          ? null
          : _normalizeApiBaseUrlForRuntime(rawComplianceConsentUrl.trim());
      _stripePublishableKey = dartDefinedStripePublishableKey.isNotEmpty
          ? dartDefinedStripePublishableKey.trim()
          : dotenv.env['STRIPE_PUBLISHABLE_KEY']?.trim();
      _apiConnectTimeout = _parseDurationSeconds(
        dotenv.env['API_CONNECT_TIMEOUT_SECONDS'],
        fallback: const Duration(seconds: 10),
        min: const Duration(seconds: 2),
      );
      _apiReceiveTimeout = _parseDurationSeconds(
        dotenv.env['API_RECEIVE_TIMEOUT_SECONDS'],
        fallback: const Duration(seconds: 30),
        min: const Duration(seconds: 5),
      );
      _apiSendTimeout = _parseDurationSeconds(
        dotenv.env['API_SEND_TIMEOUT_SECONDS'],
        fallback: const Duration(seconds: 10),
        min: const Duration(seconds: 2),
      );
      _apiRefreshReceiveTimeout = _parseDurationSeconds(
        dotenv.env['API_REFRESH_RECEIVE_TIMEOUT_SECONDS'],
        fallback: const Duration(seconds: 20),
        min: const Duration(seconds: 5),
      );

      // Perform checks to ensure essential variables are present
      if (_apiBaseUrl == null ||
          _apiWsBaseUrl == null ||
          _apiHealthUrl == null ||
          _matchHubUrl == null ||
          _presenceHubUrl == null ||
          _notifyHubUrl == null) {
        LogManager.debug('''
        --------------------------------------------------------------------
        ERROR: One or more environment variables not found in .env file.
        Please ensure your .env file is in the root of your project.
        API_BASE_URL: $_apiBaseUrl
        API_HEALTH_URL: $_apiHealthUrl
        API_WS_BASE_URL: $_apiWsBaseUrl
        API_MATCH_HUB_URL: $_matchHubUrl
        API_PRESENCE_HUB_URL: $_presenceHubUrl
        API_NOTIFY_HUB_URL: $_notifyHubUrl
        --------------------------------------------------------------------
        ''');
        // In a production app, you might throw an exception here.
        throw Exception('Required environment variables are missing.');
      }
    } catch (e) {
      LogManager.debug('Error loading .env file: $e');
      rethrow;
    }
  }

  static String? _resolveAppRedirectBaseUrl() {
    const dartDefined = String.fromEnvironment('APP_REDIRECT_BASE_URL');
    final configured = dartDefined.isNotEmpty
        ? dartDefined.trim()
        : dotenv.env['APP_REDIRECT_BASE_URL']?.trim();
    if (configured != null && configured.isNotEmpty) {
      return configured;
    }

    if (!kIsWeb) {
      return null;
    }

    try {
      final base = Uri.base;
      if (base.hasScheme &&
          (base.scheme == 'http' || base.scheme == 'https') &&
          base.host.isNotEmpty) {
        return base.origin;
      }
    } catch (_) {
      // Ignore Uri.base resolution failures and fall back to null.
    }

    return null;
  }

  static bool _parseBool(String? value, {required bool fallback}) {
    if (value == null || value.trim().isEmpty) return fallback;
    switch (value.trim().toLowerCase()) {
      case '1':
      case 'true':
      case 'yes':
      case 'on':
        return true;
      case '0':
      case 'false':
      case 'no':
      case 'off':
        return false;
      default:
        return fallback;
    }
  }

  static Set<String> _parseCsvSet(
    String? value, {
    required Set<String> fallback,
  }) {
    if (value == null || value.trim().isEmpty) return fallback;
    final parsed = value
        .split(',')
        .map((item) => item.trim().toLowerCase())
        .where((item) => item.isNotEmpty)
        .toSet();
    return parsed.isEmpty ? fallback : parsed;
  }

  static Duration _parseDurationSeconds(
    String? value, {
    required Duration fallback,
    required Duration min,
  }) {
    final seconds = int.tryParse(value?.trim() ?? '');
    if (seconds == null) return fallback;
    final parsed = Duration(seconds: seconds);
    return parsed < min ? min : parsed;
  }
}
