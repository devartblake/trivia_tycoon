import 'dart:core';

/// Centralized configuration for Multiplayer.
/// Source of truth for base URLs, timeouts, and WS/HTTP endpoints.
class MultiplayerConfig {
  /// Base HTTP API endpoint (no trailing slash), e.g. https://api.example.com
  final Uri httpBase;

  /// WebSocket endpoint, e.g. wss://ws.example.com/ws
  final Uri wsUri;

  /// Request timeout for HTTP (defaults to 10s).
  final Duration httpTimeout;

  /// Heartbeat interval for WS ping/pong (defaults to 15s).
  final Duration heartbeatInterval;

  /// Initial WS connect timeout (defaults to 12s).
  final Duration connectTimeout;

  /// Whether to print verbose logs.
  final bool debugLogging;

  const MultiplayerConfig({
    required this.httpBase,
    required this.wsUri,
    this.httpTimeout = const Duration(seconds: 10),
    this.heartbeatInterval = const Duration(seconds: 15),
    this.connectTimeout = const Duration(seconds: 12),
    this.debugLogging = false,
  });

  MultiplayerConfig copyWith({
    Uri? httpBase,
    Uri? wsUri,
    Duration? httpTimeout,
    Duration? heartbeatInterval,
    Duration? connectTimeout,
    bool? debugLogging,
  }) {
    return MultiplayerConfig(
      httpBase: httpBase ?? this.httpBase,
      wsUri: wsUri ?? this.wsUri,
      httpTimeout: httpTimeout ?? this.httpTimeout,
      heartbeatInterval: heartbeatInterval ?? this.heartbeatInterval,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      debugLogging: debugLogging ?? this.debugLogging,
    );
  }

  /// Convenience factory if you keep values in environment/config storage.
  /// `getString`/`getBool` can be any abstraction you already use.
  factory MultiplayerConfig.fromLookups({
    required String Function(String key, {String fallback}) getString,
    required bool Function(String key, {bool fallback}) getBool,
  }) {
    final http = Uri.parse(getString('mp.http_base', fallback: 'https://api.example.com'));
    final ws = Uri.parse(getString('mp.ws_uri', fallback: 'wss://api.example.com/ws'));
    final debug = getBool('mp.debug', fallback: false);
    final httpTo = Duration(milliseconds: int.parse(getString('mp.http_timeout_ms', fallback: '10000')));
    final hb = Duration(milliseconds: int.parse(getString('mp.heartbeat_ms', fallback: '15000')));
    final conn = Duration(milliseconds: int.parse(getString('mp.connect_timeout_ms', fallback: '12000')));
    return MultiplayerConfig(
      httpBase: http,
      wsUri: ws,
      httpTimeout: httpTo,
      heartbeatInterval: hb,
      connectTimeout: conn,
      debugLogging: debug,
    );
  }
}
