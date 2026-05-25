import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/multiplayer/core/multiplayer_config.dart';

void main() {
  group('MultiplayerConfig', () {
    test('constructor sets required fields', () {
      final cfg = MultiplayerConfig(
        httpBase: Uri.parse('https://api.example.com'),
        wsUri: Uri.parse('wss://api.example.com/ws'),
      );
      expect(cfg.httpBase.host, 'api.example.com');
      expect(cfg.wsUri.scheme, 'wss');
    });

    test('defaults: 10s/15s/12s timeouts, debugLogging=false', () {
      final cfg = MultiplayerConfig(
        httpBase: Uri.parse('https://api.example.com'),
        wsUri: Uri.parse('wss://api.example.com/ws'),
      );
      expect(cfg.httpTimeout, const Duration(seconds: 10));
      expect(cfg.heartbeatInterval, const Duration(seconds: 15));
      expect(cfg.connectTimeout, const Duration(seconds: 12));
      expect(cfg.debugLogging, isFalse);
    });

    test('copyWith overrides individual fields', () {
      final base = MultiplayerConfig(
        httpBase: Uri.parse('https://api.example.com'),
        wsUri: Uri.parse('wss://api.example.com/ws'),
      );
      final modified = base.copyWith(
        debugLogging: true,
        httpTimeout: const Duration(seconds: 5),
      );
      expect(modified.debugLogging, isTrue);
      expect(modified.httpTimeout, const Duration(seconds: 5));
      expect(modified.wsUri, base.wsUri);
    });

    test('copyWith with no args preserves all values', () {
      final cfg = MultiplayerConfig(
        httpBase: Uri.parse('https://api.example.com'),
        wsUri: Uri.parse('wss://api.example.com/ws'),
        debugLogging: true,
      );
      final copy = cfg.copyWith();
      expect(copy.httpBase, cfg.httpBase);
      expect(copy.wsUri, cfg.wsUri);
      expect(copy.debugLogging, isTrue);
    });

    group('fromLookups', () {
      test('uses getString/getBool callback results', () {
        final cfg = MultiplayerConfig.fromLookups(
          getString: (key, {String fallback = ''}) {
            const values = {
              'mp.http_base': 'https://custom.api.com',
              'mp.ws_uri': 'wss://custom.api.com/ws',
              'mp.http_timeout_ms': '5000',
              'mp.heartbeat_ms': '8000',
              'mp.connect_timeout_ms': '6000',
            };
            return values[key] ?? fallback;
          },
          getBool: (key, {bool fallback = false}) =>
              key == 'mp.debug' ? true : fallback,
        );
        expect(cfg.httpBase.host, 'custom.api.com');
        expect(cfg.wsUri.host, 'custom.api.com');
        expect(cfg.httpTimeout, const Duration(milliseconds: 5000));
        expect(cfg.heartbeatInterval, const Duration(milliseconds: 8000));
        expect(cfg.connectTimeout, const Duration(milliseconds: 6000));
        expect(cfg.debugLogging, isTrue);
      });

      test('falls back to defaults when keys are absent', () {
        final cfg = MultiplayerConfig.fromLookups(
          getString: (key, {String fallback = ''}) => fallback,
          getBool: (key, {bool fallback = false}) => fallback,
        );
        expect(cfg.httpBase.host, 'api.example.com');
        expect(cfg.wsUri.scheme, 'wss');
        expect(cfg.debugLogging, isFalse);
        expect(cfg.httpTimeout, const Duration(milliseconds: 10000));
      });
    });
  });
}
