import 'dart:convert';
import 'package:hive/hive.dart';

/// Authentication session containing tokens and user metadata
class AuthSession {
  final String accessToken;
  final String refreshToken;
  final DateTime? expiresAtUtc;
  final String? userId;

  /// Additional metadata from backend (role, premium status, etc.)
  final Map<String, dynamic>? metadata;

  AuthSession({
    required this.accessToken,
    required this.refreshToken,
    this.expiresAtUtc,
    this.userId,
    this.metadata,
  });

  bool get hasTokens =>
      accessToken.isNotEmpty &&
          refreshToken.isNotEmpty;

  bool get isExpired {
    if (expiresAtUtc == null) return false;
    return DateTime.now().toUtc().isAfter(expiresAtUtc!);
  }

  /// Get role from metadata
  String? get role {
    if (metadata == null) return null;

    // Check for single role
    if (metadata!.containsKey('role')) {
      return metadata!['role']?.toString();
    }

    // Check for multiple roles (take first)
    if (metadata!.containsKey('roles') && metadata!['roles'] is List) {
      final roles = metadata!['roles'] as List;
      if (roles.isNotEmpty) {
        return roles.first.toString();
      }
    }

    return null;
  }

  /// Get all roles from metadata
  List<String> get roles {
    if (metadata == null) return [];

    if (metadata!.containsKey('roles') && metadata!['roles'] is List) {
      return (metadata!['roles'] as List)
          .map((r) => r.toString())
          .toList();
    }

    if (metadata!.containsKey('role')) {
      return [metadata!['role'].toString()];
    }

    return [];
  }

  /// Get premium status from metadata
  bool get isPremium {
    if (metadata == null) return false;

    // Check various premium status fields
    if (metadata!.containsKey('isPremium')) {
      return metadata!['isPremium'] == true;
    }
    if (metadata!.containsKey('is_premium')) {
      return metadata!['is_premium'] == true;
    }
    if (metadata!.containsKey('premium')) {
      return metadata!['premium'] == true;
    }

    // Check subscription status
    if (metadata!.containsKey('subscriptionStatus')) {
      final status = metadata!['subscriptionStatus'].toString().toLowerCase();
      return status == 'active' || status == 'premium';
    }

    return false;
  }

  /// Get user tier from metadata
  String? get tier {
    if (metadata == null) return null;
    return metadata!['tier']?.toString();
  }

  /// Copy with method for updating session
  AuthSession copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAtUtc,
    String? userId,
    Map<String, dynamic>? metadata,
  }) {
    return AuthSession(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAtUtc: expiresAtUtc ?? this.expiresAtUtc,
      userId: userId ?? this.userId,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Create from JSON
  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      expiresAtUtc: json['expiresAtUtc'] != null
          ? DateTime.parse(json['expiresAtUtc'])
          : null,
      userId: json['userId'],
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresAtUtc': expiresAtUtc?.toIso8601String(),
      'userId': userId,
      'metadata': metadata,
    };
  }
}

/// Token store that persists auth tokens and metadata in Hive
class AuthTokenStore {
  final Box _box;

  static const _accessTokenKey = 'auth_access_token';
  static const _refreshTokenKey = 'auth_refresh_token';
  static const _expiresAtKey = 'auth_expires_at_utc';
  static const _userIdKey = 'auth_user_id';
  static const _metadataKey = 'auth_metadata'; // ← NEW: Store metadata

  AuthTokenStore(this._box);

  /// Load session from storage
  AuthSession load() {
    final accessToken = _box.get(_accessTokenKey, defaultValue: '') as String;
    final refreshToken = _box.get(_refreshTokenKey, defaultValue: '') as String;
    final expiresAtMs = _box.get(_expiresAtKey) as int?;
    final userId = _box.get(_userIdKey) as String?;
    final metadataJson = _box.get(_metadataKey) as String?;

    DateTime? expiresAtUtc;
    if (expiresAtMs != null) {
      expiresAtUtc = DateTime.fromMillisecondsSinceEpoch(expiresAtMs, isUtc: true);
    }

    Map<String, dynamic>? metadata;
    if (metadataJson != null && metadataJson.isNotEmpty) {
      try {
        metadata = jsonDecode(metadataJson) as Map<String, dynamic>;
      } catch (e) {
        print('[AuthTokenStore] Error parsing metadata: $e');
      }
    }

    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAtUtc: expiresAtUtc,
      userId: userId,
      metadata: metadata,
    );
  }

  /// Save session to storage
  Future<void> save(AuthSession session) async {
    await _box.put(_accessTokenKey, session.accessToken);
    await _box.put(_refreshTokenKey, session.refreshToken);

    if (session.expiresAtUtc != null) {
      await _box.put(_expiresAtKey, session.expiresAtUtc!.millisecondsSinceEpoch);
    }

    if (session.userId != null) {
      await _box.put(_userIdKey, session.userId);
    }

    // Save metadata if present
    if (session.metadata != null && session.metadata!.isNotEmpty) {
      final metadataJson = jsonEncode(session.metadata);
      await _box.put(_metadataKey, metadataJson);
    }
  }

  /// Clear all stored tokens and metadata
  Future<void> clear() async {
    await _box.delete(_accessTokenKey);
    await _box.delete(_refreshTokenKey);
    await _box.delete(_expiresAtKey);
    await _box.delete(_userIdKey);
    await _box.delete(_metadataKey); // ← Clear metadata too
  }

  /// Update only the access token (used during refresh)
  Future<void> updateAccessToken(String newAccessToken, DateTime expiresAtUtc) async {
    await _box.put(_accessTokenKey, newAccessToken);
    await _box.put(_expiresAtKey, expiresAtUtc.millisecondsSinceEpoch);
  }

  /// Check if tokens exist
  bool hasTokens() {
    final accessToken = _box.get(_accessTokenKey, defaultValue: '') as String;
    final refreshToken = _box.get(_refreshTokenKey, defaultValue: '') as String;
    return accessToken.isNotEmpty && refreshToken.isNotEmpty;
  }

  /// Get role from stored metadata
  String? getRole() {
    final metadataJson = _box.get(_metadataKey) as String?;
    if (metadataJson == null || metadataJson.isEmpty) return null;

    try {
      final metadata = jsonDecode(metadataJson) as Map<String, dynamic>;

      if (metadata.containsKey('role')) {
        return metadata['role']?.toString();
      }

      if (metadata.containsKey('roles') && metadata['roles'] is List) {
        final roles = metadata['roles'] as List;
        if (roles.isNotEmpty) {
          return roles.first.toString();
        }
      }
    } catch (e) {
      print('[AuthTokenStore] Error getting role: $e');
    }

    return null;
  }

  /// Get premium status from stored metadata
  bool isPremium() {
    final metadataJson = _box.get(_metadataKey) as String?;
    if (metadataJson == null || metadataJson.isEmpty) return false;

    try {
      final metadata = jsonDecode(metadataJson) as Map<String, dynamic>;

      if (metadata.containsKey('isPremium')) {
        return metadata['isPremium'] == true;
      }
      if (metadata.containsKey('is_premium')) {
        return metadata['is_premium'] == true;
      }
      if (metadata.containsKey('premium')) {
        return metadata['premium'] == true;
      }
    } catch (e) {
      print('[AuthTokenStore] Error getting premium status: $e');
    }

    return false;
  }
}
