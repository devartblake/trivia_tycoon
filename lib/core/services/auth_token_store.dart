import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';
import 'package:trivia_tycoon/core/services/storage/secure_secret_store.dart';

/// Authentication session containing tokens and user metadata.
class AuthSession {
  final String accessToken;
  final String refreshToken;
  final DateTime? expiresAtUtc;
  final String? userId;

  /// Additional metadata from backend (role, premium status, etc.).
  final Map<String, dynamic>? metadata;

  AuthSession({
    required this.accessToken,
    required this.refreshToken,
    this.expiresAtUtc,
    this.userId,
    this.metadata,
  });

  bool get hasTokens => accessToken.isNotEmpty && refreshToken.isNotEmpty;

  bool get isExpired {
    if (expiresAtUtc == null) return false;
    return DateTime.now().toUtc().isAfter(expiresAtUtc!);
  }

  String? get role {
    if (metadata == null) return null;

    if (metadata!.containsKey('role')) {
      return metadata!['role']?.toString();
    }

    if (metadata!.containsKey('roles') && metadata!['roles'] is List) {
      final roles = metadata!['roles'] as List;
      if (roles.isNotEmpty) {
        return roles.first.toString();
      }
    }

    return null;
  }

  List<String> get roles {
    if (metadata == null) return [];

    if (metadata!.containsKey('roles') && metadata!['roles'] is List) {
      return (metadata!['roles'] as List).map((r) => r.toString()).toList();
    }

    if (metadata!.containsKey('role')) {
      return [metadata!['role'].toString()];
    }

    return [];
  }

  bool get isPremium {
    if (metadata == null) return false;

    if (metadata!.containsKey('isPremium')) {
      return metadata!['isPremium'] == true;
    }
    if (metadata!.containsKey('is_premium')) {
      return metadata!['is_premium'] == true;
    }
    if (metadata!.containsKey('premium')) {
      return metadata!['premium'] == true;
    }

    if (metadata!.containsKey('subscriptionStatus')) {
      final status = metadata!['subscriptionStatus'].toString().toLowerCase();
      return status == 'active' || status == 'premium';
    }

    return false;
  }

  String? get tier {
    if (metadata == null) return null;
    return metadata!['tier']?.toString();
  }

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

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      expiresAtUtc: json['expiresAtUtc'] != null
          ? DateTime.parse(json['expiresAtUtc'])
          : null,
      userId: json['userId'],
      metadata: json['metadata'] == null
          ? null
          : Map<String, dynamic>.from(json['metadata'] as Map),
    );
  }

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

/// Auth tokens live in secure storage. Hive keeps only non-secret metadata for
/// synchronous role/premium reads and migration from older app versions.
class AuthTokenStore {
  final Box _box;
  final SecretStore _secretStore;

  static const _secureSessionKey = 'auth_session_v1';
  static const _accessTokenKey = 'auth_access_token';
  static const _refreshTokenKey = 'auth_refresh_token';
  static const _expiresAtKey = 'auth_expires_at_utc';
  static const _userIdKey = 'auth_user_id';
  static const _metadataKey = 'auth_metadata';

  AuthSession _cachedSession = AuthSession(accessToken: '', refreshToken: '');
  bool _initialized = false;

  AuthTokenStore(this._box, {SecretStore? secretStore})
      : _secretStore = secretStore ?? SecureSecretStore() {
    _cachedSession = _loadLegacyFromHive();
  }

  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    final secureJson = await _secretStore.get(_secureSessionKey);
    if (secureJson != null && secureJson.isNotEmpty) {
      try {
        _cachedSession = AuthSession.fromJson(
            jsonDecode(secureJson) as Map<String, dynamic>);
        await _deleteLegacyTokenValues();
        await _persistNonSecretMetadata(_cachedSession);
        _initialized = true;
        return;
      } catch (e) {
        LogManager.debug('[AuthTokenStore] Error parsing secure session: $e');
      }
    }

    final legacySession = _loadLegacyFromHive();
    _cachedSession = legacySession;
    if (legacySession.hasTokens) {
      await _persistSecureSession(legacySession);
    }
    await _deleteLegacyTokenValues();
    _initialized = true;
  }

  AuthSession load() => _cachedSession;

  String? get accessTokenSync {
    final token = _cachedSession.accessToken;
    return token.isEmpty ? null : token;
  }

  Future<void> save(AuthSession session) async {
    _cachedSession = session;
    await _persistSecureSession(session);
    await _deleteLegacyTokenValues();
    await _persistNonSecretMetadata(session);
  }

  Future<void> clear() async {
    _cachedSession = AuthSession(accessToken: '', refreshToken: '');
    await _secretStore.delete(_secureSessionKey);
    await _deleteLegacyTokenValues();
    await _box.delete(_expiresAtKey);
    await _box.delete(_userIdKey);
    await _box.delete(_metadataKey);
  }

  Future<void> updateAccessToken(
    String newAccessToken,
    DateTime expiresAtUtc,
  ) async {
    await save(_cachedSession.copyWith(
      accessToken: newAccessToken,
      expiresAtUtc: expiresAtUtc,
    ));
  }

  bool hasTokens() => _cachedSession.hasTokens;

  String? getRole() {
    final role = _cachedSession.role;
    if (role != null) return role;

    final metadata = _metadataFromHive();
    if (metadata == null) return null;

    if (metadata.containsKey('role')) {
      return metadata['role']?.toString();
    }

    if (metadata.containsKey('roles') && metadata['roles'] is List) {
      final roles = metadata['roles'] as List;
      if (roles.isNotEmpty) {
        return roles.first.toString();
      }
    }

    return null;
  }

  bool isPremium() {
    if (_cachedSession.metadata != null) {
      return _cachedSession.isPremium;
    }

    final metadata = _metadataFromHive();
    if (metadata == null) return false;

    try {
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
      LogManager.debug('[AuthTokenStore] Error getting premium status: $e');
    }

    return false;
  }

  AuthSession _loadLegacyFromHive() {
    final accessToken = _box.get(_accessTokenKey, defaultValue: '') as String;
    final refreshToken = _box.get(_refreshTokenKey, defaultValue: '') as String;
    final expiresAtMs = _box.get(_expiresAtKey) as int?;
    final userId = _box.get(_userIdKey) as String?;
    final metadata = _metadataFromHive();

    DateTime? expiresAtUtc;
    if (expiresAtMs != null) {
      expiresAtUtc =
          DateTime.fromMillisecondsSinceEpoch(expiresAtMs, isUtc: true);
    }

    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAtUtc: expiresAtUtc,
      userId: userId,
      metadata: metadata,
    );
  }

  Map<String, dynamic>? _metadataFromHive() {
    final metadataJson = _box.get(_metadataKey) as String?;
    if (metadataJson == null || metadataJson.isEmpty) return null;

    try {
      return jsonDecode(metadataJson) as Map<String, dynamic>;
    } catch (e) {
      LogManager.debug('[AuthTokenStore] Error parsing metadata: $e');
      return null;
    }
  }

  Future<void> _persistSecureSession(AuthSession session) async {
    if (session.hasTokens) {
      await _secretStore.set(_secureSessionKey, jsonEncode(session.toJson()));
    } else {
      await _secretStore.delete(_secureSessionKey);
    }
  }

  Future<void> _persistNonSecretMetadata(AuthSession session) async {
    if (session.expiresAtUtc != null) {
      await _box.put(
        _expiresAtKey,
        session.expiresAtUtc!.millisecondsSinceEpoch,
      );
    } else {
      await _box.delete(_expiresAtKey);
    }

    if (session.userId != null && session.userId!.isNotEmpty) {
      await _box.put(_userIdKey, session.userId);
    } else {
      await _box.delete(_userIdKey);
    }

    if (session.metadata != null && session.metadata!.isNotEmpty) {
      await _box.put(_metadataKey, jsonEncode(session.metadata));
    } else {
      await _box.delete(_metadataKey);
    }
  }

  Future<void> _deleteLegacyTokenValues() async {
    await _box.delete(_accessTokenKey);
    await _box.delete(_refreshTokenKey);
  }
}
