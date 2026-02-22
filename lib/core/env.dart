import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// A class to manage and provide environment variables from a .env file.
/// This ensures that sensitive keys and configuration-specific URLs are not
/// hardcoded in the application source code.
class EnvConfig {

  /// API Base URL
  static String? _apiBaseUrl;

  /// WebSocket Base URL
  static String? _apiWsBaseUrl;

  /// SignalR hub URLs
  static String? _matchHubUrl;
  static String? _presenceHubUrl;
  static String? _notifyHubUrl;

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
    assert(_presenceHubUrl != null, 'API_PRESENCE_HUB_URL is not loaded from .env');
    return _presenceHubUrl!;
  }

  /// Getter for the SignalR Notification hub URL.
  static String get notifyHubUrl {
    assert(_notifyHubUrl != null, 'API_NOTIFY_HUB_URL is not loaded from .env');
    return _notifyHubUrl!;
  }

  static String _normalizeWsUrl(String rawUrl) {
    final parsed = Uri.parse(rawUrl.trim());

    final normalizedScheme = switch (parsed.scheme) {
      'https' => 'wss',
      'http' => 'ws',
      _ => parsed.scheme,
    };

    var normalizedPath = parsed.path;
    if (normalizedPath.endsWith('/')) {
      normalizedPath = normalizedPath.substring(0, normalizedPath.length - 1);
    }

    return parsed
        .replace(
          scheme: normalizedScheme,
          path: normalizedPath,
          fragment: '',
        )
        .toString();
  }

  static String _joinWsPath(String baseUrl, String suffixPath) {
    final baseUri = Uri.parse(baseUrl);
    final baseSegments = baseUri.pathSegments.where((s) => s.isNotEmpty).toList();
    final suffixSegments = Uri.parse(suffixPath).pathSegments.where((s) => s.isNotEmpty).toList();

    final mergedSegments = <String>[...baseSegments];
    if (mergedSegments.isNotEmpty && suffixSegments.isNotEmpty && mergedSegments.last == suffixSegments.first) {
      mergedSegments.addAll(suffixSegments.skip(1));
    } else {
      mergedSegments.addAll(suffixSegments);
    }

    return baseUri.replace(pathSegments: mergedSegments, fragment: '').toString();
  }

  /// Loads all environment variables from the .env file into memory.
  /// This must be called once during app initialization before any services
  /// that rely on these variables are created.
  static Future<void> load() async {
    try {
      await dotenv.load(fileName: ".env");

      // Load variables from the environment
      _apiBaseUrl = dotenv.env['API_BASE_URL'];
      final configuredWsBase = dotenv.env['API_WS_BASE_URL'];
      final derivedWsBase = _apiBaseUrl == null ? null : _normalizeWsUrl(_apiBaseUrl!);
      _apiWsBaseUrl = configuredWsBase == null
          ? derivedWsBase
          : _normalizeWsUrl(configuredWsBase);

      _matchHubUrl = dotenv.env['API_MATCH_HUB_URL'] ??
          (_apiWsBaseUrl == null ? null : _joinWsPath(_apiWsBaseUrl!, '/ws/match'));
      _presenceHubUrl = dotenv.env['API_PRESENCE_HUB_URL'] ??
          (_apiWsBaseUrl == null ? null : _joinWsPath(_apiWsBaseUrl!, '/ws/presence'));
      _notifyHubUrl = dotenv.env['API_NOTIFY_HUB_URL'] ??
          (_apiWsBaseUrl == null ? null : _joinWsPath(_apiWsBaseUrl!, '/ws/notify'));

      // Perform checks to ensure essential variables are present
      if (_apiBaseUrl == null ||
          _apiWsBaseUrl == null ||
          _matchHubUrl == null ||
          _presenceHubUrl == null ||
          _notifyHubUrl == null) {
        debugPrint('''
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
      debugPrint('Error loading .env file: $e');
      rethrow;
    }
  }
}
