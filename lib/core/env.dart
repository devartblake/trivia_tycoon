import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

/// A class to manage and provide environment variables from a .env file.
/// This ensures that sensitive keys and configuration-specific URLs are not
/// hardcoded in the application source code.
class EnvConfig {
  /// API Base URL
  static String? _apiBaseUrl = '';

  /// WebSocket Base URL
  static String? _apiWsBaseUrl = '';

  /// SignalR hub URLs
  static String? _matchHubUrl;
  static String? _presenceHubUrl;
  static String? _notifyHubUrl;
  static String? _appRedirectBaseUrl;
  static bool _cryptoSurfacesEnabled = true;
  static bool _cryptoWritesEnabled = true;
  static Set<String> _enabledCryptoNetworks = const {'solana', 'xrp'};

  /// Getter for the backend API Base URL.
  static String get apiBaseUrl {
    assert(_apiBaseUrl != null, 'API_BASE_URL is not loaded from .env');
    return _apiBaseUrl!;
  }

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

    return baseUri
        .replace(pathSegments: mergedSegments, fragment: '')
        .toString();
  }

  static String _normalizeApiBaseUrlForRuntime(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return trimmed;

    Uri parsed = Uri.parse(trimmed);

    // ── 1. Downgrade https → http for well-known local dev addresses.
    // Local dev backends almost never have valid SSL certs, so https:// to
    // localhost / 10.0.2.2 / 127.0.0.1 fails with a handshake error on every
    // platform. Convert silently so a .env typo doesn't block development.
    const localHosts = {'localhost', '10.0.2.2', '127.0.0.1'};
    if (parsed.scheme == 'https' && localHosts.contains(parsed.host)) {
      LogManager.debug(
        '[EnvConfig] Downgrading https→http for local dev address: $trimmed',
      );
      parsed = parsed.replace(scheme: 'http');
    }

    // ── 2. Platform-aware host rewriting for 10.0.2.2 (Android emulator loopback).
    // • Web (Edge / Chrome): browsers cannot reach 10.0.2.2 — rewrite to localhost.
    // • Android native emulator: 10.0.2.2 is exactly right — leave it alone.
    // • iOS simulator / macOS / desktop: 10.0.2.2 is unreachable — rewrite to localhost.
    if (parsed.host == '10.0.2.2') {
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
    // itself, not the host machine running the dev server. Rewrite so a .env
    // with API_BASE_URL=http://localhost:5000 still reaches the backend.
    if (!kIsWeb &&
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

  /// Loads all environment variables from the .env file into memory.
  /// This must be called once during app initialization before any services
  /// that rely on these variables are created.
  static Future<void> load() async {
    try {
      await dotenv.load(fileName: ".env");

      // Load variables from the environment
      final rawApiBaseUrl =
          dotenv.get('API_BASE_URL', fallback: 'http://localhost:5000');
      _apiBaseUrl = _normalizeApiBaseUrlForRuntime(rawApiBaseUrl);

      // Derive WebSocket URL from HTTP URL
      // Convert http:// to ws:// and https:// to wss://
      _apiWsBaseUrl =
          '${apiBaseUrl.replaceFirst('http://', 'ws://').replaceFirst('https://', 'wss://')}/ws';

      LogManager.debug('[EnvConfig] API Base: $apiBaseUrl');
      LogManager.debug('[EnvConfig] WebSocket: $apiWsBaseUrl');

      _matchHubUrl = dotenv.env['API_MATCH_HUB_URL'] ??
          (_apiWsBaseUrl == null
              ? null
              : _joinWsPath(_apiWsBaseUrl!, '/ws/match'));
      _presenceHubUrl = dotenv.env['API_PRESENCE_HUB_URL'] ??
          (_apiWsBaseUrl == null
              ? null
              : _joinWsPath(_apiWsBaseUrl!, '/ws/presence'));
      _notifyHubUrl = dotenv.env['API_NOTIFY_HUB_URL'] ??
          (_apiWsBaseUrl == null
              ? null
              : _joinWsPath(_apiWsBaseUrl!, '/ws/notify'));
      _appRedirectBaseUrl = _resolveAppRedirectBaseUrl();
      _cryptoSurfacesEnabled = _parseBool(
        dotenv.env['CRYPTO_SURFACES_ENABLED'],
        fallback: true,
      );
      _cryptoWritesEnabled = _parseBool(
        dotenv.env['CRYPTO_WRITES_ENABLED'],
        fallback: true,
      );
      _enabledCryptoNetworks = _parseCsvSet(
        dotenv.env['CRYPTO_ENABLED_NETWORKS'],
        fallback: const {'solana', 'xrp'},
      );

      // Perform checks to ensure essential variables are present
      if (_apiBaseUrl == null ||
          _apiWsBaseUrl == null ||
          _matchHubUrl == null ||
          _presenceHubUrl == null ||
          _notifyHubUrl == null) {
        LogManager.debug('''
        --------------------------------------------------------------------
        ERROR: One or more environment variables not found in .env file.
        Please ensure your .env file is in the root of your project.
        API_BASE_URL: $_apiBaseUrl
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
    final configured = dotenv.env['APP_REDIRECT_BASE_URL']?.trim();
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
}
