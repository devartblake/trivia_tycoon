import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import 'package:trivia_tycoon/core/manager/log_manager.dart';
import 'package:trivia_tycoon/core/services/api_service.dart';

class ProfileSyncResult {
  final bool synced;
  final bool queuedForRetry;
  final String? confirmedDisplayName;
  final String? confirmedUsername;

  const ProfileSyncResult({
    required this.synced,
    required this.queuedForRetry,
    this.confirmedDisplayName,
    this.confirmedUsername,
  });
}

class ProfileSyncDataResult {
  final bool success;
  final String? confirmedDisplayName;
  final String? confirmedUsername;

  const ProfileSyncDataResult({
    required this.success,
    this.confirmedDisplayName,
    this.confirmedUsername,
  });
}

class ProfileSyncService {
  static const String _queueBoxName = 'profile_sync_queue';
  static const int _maxQueueSize = 100;
  static const int _maxRetryCount = 10;
  static const Duration _missingEndpointBackoff = Duration(minutes: 30);

  static final Map<String, DateTime> _endpointBackoffUntil = <String, DateTime>{};

  @visibleForTesting
  static void resetEndpointBackoffForTests() {
    _endpointBackoffUntil.clear();
  }

  final ApiService _apiService;
  final Future<void> Function(String event, Map<String, dynamic> data) _trackEvent;

  ProfileSyncService({
    required ApiService apiService,
    required Future<void> Function(String event, Map<String, dynamic> data)
        trackEvent,
  })  : _apiService = apiService,
        _trackEvent = trackEvent;

  Future<ProfileSyncResult> syncProfileUpdate({
    required String displayName,
    required String username,
  }) async {
    final payload = <String, dynamic>{
      'display_name': displayName,
      'displayName': displayName,
      'username': username,
      'handle': username,
    };

    final response = await _trySync(payload);
    if (response != null) {
      final confirmedDisplayName = _readFirstString(response, const [
        'display_name',
        'displayName',
        'name',
      ]);
      final confirmedUsername = _readFirstString(response, const [
        'username',
        'handle',
      ]);

      await _trackEvent('profile_sync_success', {
        'has_confirmed_display_name': confirmedDisplayName != null,
        'has_confirmed_username': confirmedUsername != null,
        'timestamp': DateTime.now().toIso8601String(),
      });

      return ProfileSyncResult(
        synced: true,
        queuedForRetry: false,
        confirmedDisplayName: confirmedDisplayName,
        confirmedUsername: confirmedUsername,
      );
    }

    await _enqueueRetry(payload);
    await _trackEvent('profile_sync_queued_for_retry', {
      'timestamp': DateTime.now().toIso8601String(),
    });

    return const ProfileSyncResult(synced: false, queuedForRetry: true);
  }

  Future<ProfileSyncDataResult> syncProfileData({
    required String displayName,
    String? existingUsername,
  }) async {
    final normalizedDisplayName = displayName.trim();
    final normalizedUsername =
        _normalizeUsername(existingUsername) ?? _usernameFromDisplayName(normalizedDisplayName);

    final result = await syncProfileUpdate(
      displayName: normalizedDisplayName,
      username: normalizedUsername,
    );

    return ProfileSyncDataResult(
      success: result.synced,
      confirmedDisplayName: result.confirmedDisplayName,
      confirmedUsername: result.confirmedUsername,
    );
  }

  Future<void> retryQueuedUpdates() async {
    final box = await Hive.openBox(_queueBoxName);
    final keys = box.keys.toList()
      ..sort((a, b) {
        final aData = box.get(a);
        final bData = box.get(b);
        final aCreated = _parseIso((aData is Map) ? aData['created_at'] : null);
        final bCreated = _parseIso((bData is Map) ? bData['created_at'] : null);
        return aCreated.compareTo(bCreated);
      });

    for (final key in keys) {
      final data = box.get(key);
      if (data is! Map) continue;

      final retryCount = (data['retry_count'] as int? ?? 0);
      if (retryCount >= _maxRetryCount) {
        await box.delete(key);
        await _trackEvent('profile_sync_dropped_max_retries', {
          'max_retry_count': _maxRetryCount,
          'created_at': data['created_at'],
          'dropped_at': DateTime.now().toIso8601String(),
        });
        LogManager.warning(
          'Dropped queued profile sync item after max retries ($retryCount)',
          source: 'ProfileSyncService',
        );
        continue;
      }

      final payload = Map<String, dynamic>.from(data['payload'] as Map? ?? const {});
      if (payload.isEmpty) {
        await box.delete(key);
        continue;
      }

      final synced = await _trySync(payload);
      if (synced != null) {
        await box.delete(key);
      } else {
        final updatedRetryCount = retryCount + 1;
        await box.put(key, {
          ...data,
          'retry_count': updatedRetryCount,
          'last_retry': DateTime.now().toIso8601String(),
        });
      }
    }
  }

  Future<Map<String, dynamic>> getQueueDiagnostics() async {
    final box = await Hive.openBox(_queueBoxName);
    if (box.isEmpty) {
      return {
        'queue_length': 0,
        'max_queue_size': _maxQueueSize,
        'max_retry_count': _maxRetryCount,
        'oldest_created_at': null,
        'newest_created_at': null,
        'highest_retry_count': 0,
      };
    }

    DateTime? oldest;
    DateTime? newest;
    var highestRetryCount = 0;

    for (final key in box.keys) {
      final data = box.get(key);
      if (data is! Map) continue;

      final createdAt = _parseIso(data['created_at']);
      final retryCount = data['retry_count'] as int? ?? 0;

      if (oldest == null || createdAt.isBefore(oldest)) oldest = createdAt;
      if (newest == null || createdAt.isAfter(newest)) newest = createdAt;
      if (retryCount > highestRetryCount) highestRetryCount = retryCount;
    }

    return {
      'queue_length': box.length,
      'max_queue_size': _maxQueueSize,
      'max_retry_count': _maxRetryCount,
      'oldest_created_at': oldest?.toIso8601String(),
      'newest_created_at': newest?.toIso8601String(),
      'highest_retry_count': highestRetryCount,
    };
  }

  Future<Map<String, dynamic>?> _trySync(Map<String, dynamic> payload) async {
    const endpoints = <String>[
      '/users/me',
      '/profile',
      '/user/profile',
      '/auth/profile',
    ];

    for (final endpoint in endpoints) {
      if (_isEndpointInBackoff(endpoint)) {
        continue;
      }

      try {
        final response = await _apiService.patch(
          endpoint,
          body: payload,
          headers: _authHeaders(),
        );
        _clearEndpointBackoff(endpoint);
        return response;
      } on ApiRequestException catch (e) {
        if (e.statusCode == 404) {
          _markEndpointInBackoff(endpoint);
          await _trackEvent('profile_sync_endpoint_unavailable', {
            'endpoint': endpoint,
            'status_code': 404,
            'backoff_seconds': _missingEndpointBackoff.inSeconds,
            'timestamp': DateTime.now().toIso8601String(),
          });
          LogManager.info(
            'Endpoint unavailable (404). Backing off endpoint $endpoint for ${_missingEndpointBackoff.inMinutes}m',
            source: 'ProfileSyncService',
          );
          continue;
        }

        LogManager.warning(
          'Endpoint failed ($endpoint): $e',
          source: 'ProfileSyncService',
        );
      } catch (e) {
        LogManager.warning(
          'Endpoint failed ($endpoint): $e',
          source: 'ProfileSyncService',
        );
      }
    }

    return null;
  }

  bool _isEndpointInBackoff(String endpoint) {
    final until = _endpointBackoffUntil[endpoint];
    if (until == null) return false;

    final now = DateTime.now();
    if (now.isAfter(until)) {
      _endpointBackoffUntil.remove(endpoint);
      return false;
    }
    return true;
  }

  void _markEndpointInBackoff(String endpoint) {
    _endpointBackoffUntil[endpoint] = DateTime.now().add(_missingEndpointBackoff);
  }

  void _clearEndpointBackoff(String endpoint) {
    _endpointBackoffUntil.remove(endpoint);
  }

  Map<String, String>? _authHeaders() {
    if (!Hive.isBoxOpen('auth_tokens')) return null;
    final box = Hive.box('auth_tokens');
    final token = box.get('auth_access_token')?.toString().trim();
    if (token == null || token.isEmpty) return null;

    return {'Authorization': 'Bearer $token'};
  }

  Future<void> _enqueueRetry(Map<String, dynamic> payload) async {
    final box = await Hive.openBox(_queueBoxName);

    final existingKey = _findExistingPayloadKey(box, payload);
    if (existingKey != null) {
      final existingData = box.get(existingKey);
      if (existingData is Map) {
        await box.put(existingKey, {
          ...existingData,
          'payload': payload,
          'last_retry': DateTime.now().toIso8601String(),
        });
      }
      return;
    }

    await _enforceQueueLimit(box);
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    await box.put(id, {
      'payload': payload,
      'retry_count': 0,
      'created_at': DateTime.now().toIso8601String(),
      'last_retry': null,
    });
  }

  Future<void> _enforceQueueLimit(Box box) async {
    if (box.length < _maxQueueSize) return;

    final entries = box.toMap().entries.toList()
      ..sort((a, b) {
        final aCreated = _parseIso((a.value is Map) ? a.value['created_at'] : null);
        final bCreated = _parseIso((b.value is Map) ? b.value['created_at'] : null);
        return aCreated.compareTo(bCreated);
      });

    final toDelete = entries.length - _maxQueueSize + 1;
    for (var i = 0; i < toDelete; i++) {
      await box.delete(entries[i].key);
    }

    await _trackEvent('profile_sync_queue_trimmed', {
      'deleted_count': toDelete,
      'queue_limit': _maxQueueSize,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  dynamic _findExistingPayloadKey(Box box, Map<String, dynamic> payload) {
    for (final key in box.keys) {
      final data = box.get(key);
      if (data is! Map) continue;
      final existingPayload = Map<String, dynamic>.from(
        data['payload'] as Map? ?? const {},
      );
      if (_payloadSignature(existingPayload) == _payloadSignature(payload)) {
        return key;
      }
    }
    return null;
  }

  String _payloadSignature(Map<String, dynamic> payload) {
    final displayName = payload['display_name'] ?? payload['displayName'] ?? '';
    final username = payload['username'] ?? payload['handle'] ?? '';
    return '${displayName.toString().trim().toLowerCase()}|${username.toString().trim().toLowerCase()}';
  }

  DateTime _parseIso(Object? raw) {
    if (raw is String) {
      return DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  String? _normalizeUsername(String? raw) {
    if (raw == null) return null;
    final normalized = raw
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
    if (normalized.isEmpty) return null;
    return normalized;
  }

  String _usernameFromDisplayName(String displayName) {
    final generated = _normalizeUsername(displayName);
    return generated ?? 'player';
  }

  String? _readFirstString(Map<String, dynamic> response, List<String> keys) {
    for (final key in keys) {
      final value = response[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    final user = response['user'];
    if (user is Map) {
      final nested = Map<String, dynamic>.from(user);
      for (final key in keys) {
        final value = nested[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
    }

    return null;
  }
}
