import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/services/audio/audio_asset_response.dart';

void main() {
  // -------------------------------------------------------------------------
  // AudioAssetResponse — direct construction
  // -------------------------------------------------------------------------

  group('AudioAssetResponse constructor', () {
    test('stores all required fields', () {
      final expiry = DateTime(2024, 12, 31, 23, 59);
      const response = AudioAssetResponse(
        presignedUrl: 'https://example.com/song.mp3',
        expiresAt: DateTime.utc(2024, 12, 31, 23, 59),
        contentType: 'audio/mpeg',
      );
      expect(response.presignedUrl, 'https://example.com/song.mp3');
      expect(response.contentType, 'audio/mpeg');
    });

    test('cacheDuration defaults to null', () {
      const response = AudioAssetResponse(
        presignedUrl: 'https://example.com/a.mp3',
        expiresAt: DateTime.utc(2025, 1, 1),
        contentType: 'audio/mpeg',
      );
      expect(response.cacheDuration, isNull);
    });

    test('cacheDuration can be set', () {
      const response = AudioAssetResponse(
        presignedUrl: 'https://example.com/a.mp3',
        expiresAt: DateTime.utc(2025, 1, 1),
        contentType: 'audio/ogg',
        cacheDuration: Duration(seconds: 300),
      );
      expect(response.cacheDuration, const Duration(seconds: 300));
    });
  });

  // -------------------------------------------------------------------------
  // AudioAssetResponse.fromJson — happy path
  // -------------------------------------------------------------------------

  group('AudioAssetResponse.fromJson — all fields provided', () {
    final json = {
      'presignedUrl': 'https://cdn.example.com/track.mp3',
      'expiresAt': '2024-06-15T12:00:00.000Z',
      'contentType': 'audio/ogg',
    };

    test('presignedUrl is parsed correctly', () {
      final r = AudioAssetResponse.fromJson(json);
      expect(r.presignedUrl, 'https://cdn.example.com/track.mp3');
    });

    test('expiresAt is parsed to correct DateTime', () {
      final r = AudioAssetResponse.fromJson(json);
      expect(r.expiresAt, DateTime.parse('2024-06-15T12:00:00.000Z'));
    });

    test('contentType is stored correctly', () {
      final r = AudioAssetResponse.fromJson(json);
      expect(r.contentType, 'audio/ogg');
    });

    test('cacheDuration is null when cacheHints is absent', () {
      final r = AudioAssetResponse.fromJson(json);
      expect(r.cacheDuration, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // AudioAssetResponse.fromJson — contentType default
  // -------------------------------------------------------------------------

  group('AudioAssetResponse.fromJson — contentType default', () {
    test('missing contentType defaults to "audio/mpeg"', () {
      final json = {
        'presignedUrl': 'https://example.com/a.mp3',
        'expiresAt': '2025-01-01T00:00:00.000Z',
        // no contentType key
      };
      final r = AudioAssetResponse.fromJson(json);
      expect(r.contentType, 'audio/mpeg');
    });

    test('null contentType defaults to "audio/mpeg"', () {
      final json = {
        'presignedUrl': 'https://example.com/a.mp3',
        'expiresAt': '2025-01-01T00:00:00.000Z',
        'contentType': null,
      };
      final r = AudioAssetResponse.fromJson(json);
      expect(r.contentType, 'audio/mpeg');
    });
  });

  // -------------------------------------------------------------------------
  // AudioAssetResponse.fromJson — cacheHints / cacheDuration
  // -------------------------------------------------------------------------

  group('AudioAssetResponse.fromJson — cacheHints', () {
    final baseJson = {
      'presignedUrl': 'https://example.com/a.mp3',
      'expiresAt': '2025-06-01T00:00:00.000Z',
    };

    test('cacheHints: null → cacheDuration is null', () {
      final json = {...baseJson, 'cacheHints': null};
      final r = AudioAssetResponse.fromJson(json);
      expect(r.cacheDuration, isNull);
    });

    test('cacheHints with maxAgeSeconds:120 → Duration(seconds:120)', () {
      final json = {
        ...baseJson,
        'cacheHints': {'maxAgeSeconds': 120},
      };
      final r = AudioAssetResponse.fromJson(json);
      expect(r.cacheDuration, const Duration(seconds: 120));
    });

    test('cacheHints with maxAgeSeconds:3600 → Duration(seconds:3600)', () {
      final json = {
        ...baseJson,
        'cacheHints': {'maxAgeSeconds': 3600},
      };
      final r = AudioAssetResponse.fromJson(json);
      expect(r.cacheDuration, const Duration(seconds: 3600));
    });

    test('cacheHints without maxAgeSeconds → cacheDuration is null', () {
      final json = {
        ...baseJson,
        'cacheHints': {'otherKey': 'value'},
      };
      final r = AudioAssetResponse.fromJson(json);
      expect(r.cacheDuration, isNull);
    });

    test('cacheHints with non-int maxAgeSeconds → cacheDuration is null', () {
      final json = {
        ...baseJson,
        'cacheHints': {'maxAgeSeconds': 'not-an-int'},
      };
      final r = AudioAssetResponse.fromJson(json);
      expect(r.cacheDuration, isNull);
    });
  });
}
