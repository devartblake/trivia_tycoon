import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import 'package:trivia_tycoon/core/services/api_service.dart';
import 'package:trivia_tycoon/game/analytics/services/analytics_service.dart';

class ProfileSyncResult {
  final bool success;
  final bool synced;
  final bool queuedForRetry;
  final String? confirmedDisplayName;
  final String? confirmedUsername;

  const ProfileSyncResult({
    required this.success,
    required this.synced,
    required this.queuedForRetry,
    this.confirmedDisplayName,
    this.confirmedUsername,
  });
}

class ProfileSyncService {
  static const String _queueBoxName = 'profile_sync_queue';

  final ApiService _apiService;
  final AnalyticsService _analyticsService;

  ProfileSyncService({
    required ApiService apiService,
    required AnalyticsService analyticsService,
  })  : _apiService = apiService,
        _analyticsService = analyticsService;

  /// Sync profile data with optional username generation
  Future<ProfileSyncResult> syncProfileData({
    required String displayName,
    String? existingUsername,
  }) async {
    // Generate username from display name if none exists
    final username = existingUsername != null && existingUsername.trim().isNotEmpty
        ? existingUsername.trim().toLowerCase()
        : _generateUsernameFromDisplayName(displayName);

    // Call the existing sync method
    final result = await syncProfileUpdate(
      displayName: displayName,
      username: username,
    );

    // Return result with success field
    return ProfileSyncResult(
      success: result.synced,
      synced: result.synced,
      queuedForRetry: result.queuedForRetry,
      confirmedDisplayName: result.confirmedDisplayName,
      confirmedUsername: result.confirmedUsername,
    );
  }

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

      await _analyticsService.trackEvent('profile_sync_success', {
        'has_confirmed_display_name': confirmedDisplayName != null,
        'has_confirmed_username': confirmedUsername != null,
        'timestamp': DateTime.now().toIso8601String(),
      });

      return ProfileSyncResult(
        success: true,
        synced: true,
        queuedForRetry: false,
        confirmedDisplayName: confirmedDisplayName,
        confirmedUsername: confirmedUsername,
      );
    }

    await _enqueueRetry(payload);
    await _analyticsService.trackEvent('profile_sync_queued_for_retry', {
      'timestamp': DateTime.now().toIso8601String(),
    });

    return const ProfileSyncResult(
      success: false,
      synced: false,
      queuedForRetry: true,
    );
  }

  Future<void> retryQueuedUpdates() async {
    final box = await Hive.openBox(_queueBoxName);
    final keys = box.keys.toList();

    for (final key in keys) {
      final data = box.get(key);
      if (data is! Map) continue;

      final payload = Map<String, dynamic>.from(data['payload'] as Map? ?? const {});
      if (payload.isEmpty) {
        await box.delete(key);
        continue;
      }

      final synced = await _trySync(payload);
      if (synced != null) {
        await box.delete(key);
      } else {
        final retryCount = (data['retry_count'] as int? ?? 0) + 1;
        await box.put(key, {
          ...data,
          'retry_count': retryCount,
          'last_retry': DateTime.now().toIso8601String(),
        });
      }
    }
  }

  Future<Map<String, dynamic>?> _trySync(Map<String, dynamic> payload) async {
    const endpoints = <String>[
      '/profile',
      '/user/profile',
      '/auth/profile',
    ];

    for (final endpoint in endpoints) {
      try {
        final response = await _apiService.patch(endpoint, body: payload);
        return response;
      } catch (e) {
        debugPrint('[ProfileSync] endpoint failed ($endpoint): $e');
      }
    }

    return null;
  }

  Future<void> _enqueueRetry(Map<String, dynamic> payload) async {
    final box = await Hive.openBox(_queueBoxName);
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    await box.put(id, {
      'payload': payload,
      'retry_count': 0,
      'created_at': DateTime.now().toIso8601String(),
      'last_retry': null,
    });
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

  String _generateUsernameFromDisplayName(String displayName) {
    final normalized = displayName
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');

    if (normalized.isEmpty) return 'player';
    return normalized;
  }
}