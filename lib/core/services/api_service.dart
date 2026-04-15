import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import '_api_cache_store.dart' if (dart.library.io) '_api_cache_store_io.dart';
import '../../game/models/seasonal_competition_model.dart';
import 'analytics/config_service.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

class ApiRequestException implements Exception {
  final String message;
  final int? statusCode;
  final String? path;
  final String? errorCode;
  final Map<String, dynamic>? details;
  final Duration? retryAfter;

  ApiRequestException(
      this.message, {
        this.statusCode,
        this.path,
        this.errorCode,
        this.details,
        this.retryAfter,
      });

  @override
  String toString() {
    final code = statusCode != null ? ' ($statusCode)' : '';
    final target = path != null ? ' [$path]' : '';
    return 'ApiRequestException$code$target: $message';
  }
}

class ApiPageEnvelope<T> {
  final List<T> items;
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;

  const ApiPageEnvelope({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
  });

  bool get hasNext => page < totalPages;
  bool get hasPrevious => page > 1;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'items': items,
    'page': page,
    'pageSize': pageSize,
    'total': total,
    'totalPages': totalPages,
    'hasNext': hasNext,
    'hasPrevious': hasPrevious,
  };
}

class ApiService {
  final Dio _dio;
  final Dio _refreshDio;
  final String baseUrl;
  late CacheOptions _cacheOptions;
  late final CacheStore _cacheStore;
  late DioCacheInterceptor _cacheInterceptor;
  ApiService({
    required this.baseUrl,
    Dio? dio,
    Dio? refreshDio,
    ConfigService? configService,
    bool initializeCache = true,
  })  : _dio = dio ??
      Dio(BaseOptions(
        baseUrl: baseUrl,
        // Shorter timeouts for development to fail fast
        connectTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 3),
        sendTimeout: const Duration(seconds: 3),
      )),
        _refreshDio = refreshDio ??
            Dio(BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 5),
            )) {
    // Disable or reduce logging in release mode
    if (ConfigService.enableLogging && kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        request: false,
        requestHeader: false,
        requestBody: false,
        responseHeader: false,
        responseBody: false,
        error: true,
        logPrint: (log) => LogManager.debug("[API Log]: $log"),
      ));
    }

    if (initializeCache) {
      _initializeCache();
    }
  }

  Future<void> _initializeCache() async {
    _cacheStore = await createCacheStore();

    _cacheOptions = CacheOptions(
      store: _cacheStore,
      policy: CachePolicy.request,
      maxStale: const Duration(days: 7),
      priority: CachePriority.high,
    );
    _cacheInterceptor = DioCacheInterceptor(options: _cacheOptions);
    _dio.interceptors.add(_cacheInterceptor);
  }

  Future<List<Map<String, dynamic>>> fetchQuestions({
    required int amount,
    String? category,
    String? difficulty,
  }) async {
    return _handleRequest(() async {
      final response = await _dio.get(
        '/quiz/play',
        queryParameters: {
          'amount': amount,
          if (category != null) 'category': category,
          if (difficulty != null) 'difficulty': difficulty,
        },
        options: _cacheOptions.toOptions(),
      );
      return List<Map<String, dynamic>>.from(response.data);
    });
  }

  Future<List<Map<String, dynamic>>> fetchLeaderboard({int limit = 100}) async {
    return _handleRequest(() async {
      final response = await _dio.get(
        '/leaderboard',
        queryParameters: {
          'limit': limit,
        },
        options: _cacheOptions.toOptions(),
      );
      return List<Map<String, dynamic>>.from(response.data);
    });
  }

  Future<List<Map<String, dynamic>>> fetchAchievements(String playerName) async {
    return _handleRequest(() async {
      final response = await _dio.get(
        '/achievements',
        queryParameters: {'playerName': playerName},
        options: _cacheOptions.toOptions(),
      );
      return List<Map<String, dynamic>>.from(response.data);
    });
  }

  Future<void> submitScore(String playerName, int score) async {
    await _handleRequest(() async {
      await _dio.post('/leaderboard', data: {
        'playerName': playerName,
        'score': score,
      });
    });
  }

  Future<void> unlockAchievement(String playerName, String achievement) async {
    await _handleRequest(() async {
      await _dio.post('/achievements', data: {
        'playerName': playerName,
        'achievement': achievement,
      });
    });
  }

  Future<void> clearCache() async {
    await _cacheStore.clean();
  }

  Future<dynamic> getRequest(String endpoint) async {
    return _handleRequest(() async {
      final response = await _dio.get('$baseUrl/$endpoint');
      if (response.statusCode == 200) {
        return response.data is String
            ? jsonDecode(response.data as String)
            : response.data;
      } else {
        throw Exception("Error: ${response.statusCode}");
      }
    });
  }

  /// Unified API Request Handler with silent timeout handling
  Future<T> _handleRequest<T>(Future<T> Function() request,
      {bool allowAuthRetry = true}) async {
    try {
      return await request();
    } on DioException catch (e) {
      final isTimeoutLike = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError;

      // Preserve silent timeout/offline behavior while keeping exception type consistent.
      if (isTimeoutLike) {
        if (ConfigService.enableLogging && kDebugMode) {
          LogManager.debug(
              "[API Timeout]: ${e.requestOptions.path} - No backend available");
        }

        throw ApiRequestException(
          'API Timeout',
          statusCode: e.response?.statusCode,
          path: e.requestOptions.path,
        );
      }

      final envelope = _extractErrorEnvelope(e.response?.data);
      final retryAfterDuration = _extractRetryAfter(e);
      var normalizedMessage =
      _extractErrorMessageFromResponse(e, envelope: envelope);

      if (_shouldAttemptRefresh(e, allowAuthRetry)) {
        final refreshed = await _refreshSessionToken();
        if (refreshed) {
          return _handleRequest(request, allowAuthRetry: false);
        }
      }

      if (e.response?.statusCode == 429 && retryAfterDuration != null) {
        normalizedMessage =
        '$normalizedMessage (retry after ${retryAfterDuration.inSeconds}s)';
      }

      await _handleErrorCodeSideEffects(e.response?.statusCode);

      // Log other Dio errors normally
      if (ConfigService.enableLogging) {
        LogManager.debug("API Error [Dio]: $normalizedMessage");
      }

      throw ApiRequestException(
        normalizedMessage,
        statusCode: e.response?.statusCode,
        path: e.requestOptions.path,
        errorCode: envelope['code']?.toString(),
        details: envelope['details'] as Map<String, dynamic>?,
        retryAfter: retryAfterDuration,
      );
    } catch (e) {
      if (ConfigService.enableLogging) {
        LogManager.debug("API Error: $e");
      }
      if (e is ApiRequestException) rethrow;
      throw Exception("Unexpected Error: $e");
    }
  }

  String _extractErrorMessageFromResponse(DioException e,
      {Map<String, dynamic>? envelope}) {
    final responseData = e.response?.data;

    final responseMap = envelope ??
        (responseData is Map ? _asJsonMap(responseData) : <String, dynamic>{});
    if (responseMap.isNotEmpty) {
      final nestedError = responseMap['error'];
      if (nestedError is Map) {
        final nestedErrorMap = _asJsonMap(nestedError);
        final nestedMessage = nestedErrorMap['message'];
        if (nestedMessage is String && nestedMessage.trim().isNotEmpty) {
          return nestedMessage.trim();
        }
      }

      for (final key in const ['message', 'error', 'detail', 'title']) {
        final value = responseMap[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
    }

    if (responseData is String && responseData.trim().isNotEmpty) {
      return responseData.trim();
    }

    return e.message ?? 'Request failed';
  }

  Map<String, dynamic> _asJsonMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, entry) => MapEntry(key.toString(), entry));
    }
    return <String, dynamic>{};
  }

  String? _loadAccessToken() {
    if (!Hive.isBoxOpen('auth_tokens')) return null;
    final box = Hive.box('auth_tokens');
    final token = box.get('auth_access_token')?.toString();
    if (token == null || token.trim().isEmpty) return null;
    return token.trim();
  }

  Map<String, String> _buildJsonHeaders(String path,
      [Map<String, String>? headers]) {
    final resolved = <String, String>{
      'Content-Type': 'application/json',
      if (headers != null) ...headers,
    };

    final hasAuthorization =
    resolved.keys.any((key) => key.toLowerCase() == 'authorization');

    if (!hasAuthorization && _isProtectedPath(path)) {
      final accessToken = _loadAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        resolved['Authorization'] = 'Bearer $accessToken';
      }
    }

    return resolved;
  }

  /// Loads mock data from assets/json
  Future<dynamic> getMockData(String filename) async {
    final String jsonString =
    await rootBundle.loadString('assets/data/analytics/$filename');
    return jsonDecode(jsonString);
  }

  /// **🔹 Generic POST Request**
  /// Sends a POST request to the specified [path] with a JSON [data] payload.
  /// Handles errors using the unified [_handleRequest] wrapper.
  /// FIX: Returns a type-safe Map for predictable JSON responses.
  Future<Map<String, dynamic>> post(String path,
      {required Map<String, dynamic> body,
        Map<String, String>? headers}) async {
    return _handleRequest(() async {
      final response = await _dio.post(
        path,
        data: body,
        options: Options(headers: _buildJsonHeaders(path, headers)),
      );
      // Ensure the response data is a map, otherwise return an empty map.
      return _asJsonMap(response.data);
    });
  }

  /// **🔹 Generic GET Request (JSON map response)**
  Future<Map<String, dynamic>> get(String path,
      {Map<String, String>? headers,
        Map<String, dynamic>? queryParameters}) async {
    return _handleRequest(() async {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: Options(headers: _buildJsonHeaders(path, headers)),
      );
      return _asJsonMap(response.data);
    });
  }

  /// **🔹 Generic DELETE Request**
  Future<Map<String, dynamic>> delete(String path,
      {Map<String, dynamic>? body,
        Map<String, String>? headers}) async {
    return _handleRequest(() async {
      final response = await _dio.delete(
        path,
        data: body,
        options: Options(headers: _buildJsonHeaders(path, headers)),
      );
      return _asJsonMap(response.data);
    });
  }

  /// Generic GET request for endpoints that return a JSON array.
  Future<List<Map<String, dynamic>>> getList(String path,
      {Map<String, String>? headers,
        Map<String, dynamic>? queryParameters}) async {
    return _handleRequest(() async {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: Options(headers: _buildJsonHeaders(path, headers)),
      );

      final data = response.data;
      if (data is List) {
        return data
            .whereType<Map>()
            .map((item) => _asJsonMap(item))
            .toList(growable: false);
      }

      throw ApiRequestException(
        'Expected a JSON array response',
        statusCode: response.statusCode,
        path: path,
      );
    });
  }

  /// **🔹 Generic PATCH Request**
  Future<Map<String, dynamic>> patch(String path,
      {required Map<String, dynamic> body,
        Map<String, String>? headers}) async {
    return _handleRequest(() async {
      final response = await _dio.patch(
        path,
        data: body,
        options: Options(headers: _buildJsonHeaders(path, headers)),
      );
      return _asJsonMap(response.data);
    });
  }

  /// **🔹 Generic PUT Request**
  Future<Map<String, dynamic>> put(String path,
      {required Map<String, dynamic> body,
        Map<String, String>? headers}) async {
    return _handleRequest(() async {
      final response = await _dio.put(
        path,
        data: body,
        options: Options(headers: _buildJsonHeaders(path, headers)),
      );
      return _asJsonMap(response.data);
    });
  }

  /// Parses common paginated envelope variants into a typed structure.
  /// Supports optional itemParser as second positional parameter.
  ApiPageEnvelope<T> parsePageEnvelope<T>(
      Map<String, dynamic> response,
      [T Function(Map<String, dynamic>)? itemParser]) {
    // Default data keys to try
    const dataKeys = ['items', 'data', 'results', 'rows'];
    List<dynamic> rawItems = const <dynamic>[];

    for (final key in dataKeys) {
      final candidate = response[key];
      if (candidate is List) {
        rawItems = candidate;
        break;
      }
    }

    final paginationData = _asJsonMap(response['pagination']);
    final metaData = _asJsonMap(response['meta']);
    final paging = paginationData.isNotEmpty ? paginationData : metaData;

    int? readInt(Object? value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    final page = readInt(response['page']) ?? readInt(paging['page']) ?? 1;
    final pageSize = readInt(response['pageSize']) ??
        readInt(response['limit']) ??
        readInt(paging['pageSize']) ??
        readInt(paging['limit']) ??
        rawItems.length;
    final total = readInt(response['total']) ??
        readInt(response['count']) ??
        readInt(paging['total']) ??
        readInt(paging['count']) ??
        rawItems.length;
    final totalPages = readInt(response['totalPages']) ??
        readInt(response['pages']) ??
        readInt(paging['totalPages']) ??
        readInt(paging['pages']) ??
        ((pageSize > 0) ? (total / pageSize).ceil() : 1);

    final parser = itemParser ?? (Map<String, dynamic> map) => map as T;

    final items = rawItems.map((item) {
      if (item is Map<String, dynamic>) {
        return parser(item);
      }
      if (item is Map) {
        return parser(_asJsonMap(item));
      }
      throw ApiRequestException(
          'Invalid paginated item type: ${item.runtimeType}');
    }).toList(growable: false);

    return ApiPageEnvelope<T>(
      items: items,
      page: page,
      pageSize: pageSize,
      total: total,
      totalPages: totalPages,
    );
  }

  // Compatibility helpers for branches that still reference these methods.
  bool _isProtectedPath(String path) {
    if (path == '/admin' || path.startsWith('/admin/')) return true;

    if (path == '/store' || path.startsWith('/store/')) return true;
    if (path == '/crypto' || path.startsWith('/crypto/')) return true;

    // User-scoped/profile endpoints also require auth headers and token refresh handling.
    if (path == '/users/me' || path.startsWith('/users/me/')) return true;
    if (path == '/profile' || path.startsWith('/profile/')) return true;
    if (path == '/auth/profile' || path.startsWith('/auth/profile/')) return true;
    if (path == '/user/profile' || path.startsWith('/user/profile/')) return true;

    return false;
  }

  Map<String, dynamic> _extractErrorEnvelope(Object? responseData) {
    if (responseData is Map) {
      final map = _asJsonMap(responseData);
      final nested = _asJsonMap(map['error']);
      return nested.isNotEmpty ? nested : map;
    }
    return <String, dynamic>{};
  }

  bool _shouldAttemptRefresh(DioException e, bool allowAuthRetry) {
    if (!allowAuthRetry) return false;
    if (e.response?.statusCode != 401) return false;

    final path = e.requestOptions.path;
    if (!_isProtectedPath(path)) return false;

    // Avoid refreshing on refresh endpoint itself.
    return !path.endsWith('/auth/refresh') &&
        !path.endsWith('/admin/auth/refresh');
  }

  Future<bool> _refreshSessionToken() async {
    if (!Hive.isBoxOpen('auth_tokens')) return false;

    final box = Hive.box('auth_tokens');
    final refreshToken = box.get('auth_refresh_token')?.toString() ?? '';
    if (refreshToken.trim().isEmpty) return false;

    const refreshPaths = ['/admin/auth/refresh', '/auth/refresh'];

    for (final refreshPath in refreshPaths) {
      try {
        final response = await _refreshDio.post(
          refreshPath,
          data: {
            'refreshToken': refreshToken,
            'refresh_token': refreshToken,
          },
          options: Options(headers: {'Content-Type': 'application/json'}),
        );

        final payload = _asJsonMap(response.data);
        final access = payload['accessToken']?.toString() ??
            payload['access_token']?.toString() ??
            '';
        if (access.trim().isEmpty) {
          continue;
        }

        final newRefresh = payload['refreshToken']?.toString() ??
            payload['refresh_token']?.toString() ??
            refreshToken;

        box.put('auth_access_token', access.trim());
        box.put('auth_refresh_token', newRefresh.trim());

        final expiresAtEpochMs = _resolveExpiryEpochMs(payload);
        if (expiresAtEpochMs != null) {
          box.put('auth_expires_at_utc', expiresAtEpochMs);
        } else {
          box.delete('auth_expires_at_utc');
        }

        return true;
      } on DioException catch (e) {
        final statusCode = e.response?.statusCode;
        if (statusCode == 401 || statusCode == 403) {
          await _clearSessionTokens();
          return false;
        }
        // Try the next refresh endpoint variant.
      } catch (_) {
        // Try the next refresh endpoint variant.
      }
    }

    return false;
  }

  int? _resolveExpiryEpochMs(Map<String, dynamic> payload) {
    final expiresInRaw = payload['expiresIn'] ?? payload['expires_in'];
    final expiresIn = expiresInRaw is int
        ? expiresInRaw
        : (expiresInRaw is String ? int.tryParse(expiresInRaw) : null);

    if (expiresIn != null && expiresIn > 0) {
      return DateTime.now()
          .toUtc()
          .add(Duration(seconds: expiresIn))
          .millisecondsSinceEpoch;
    }

    final expiresAtRaw =
        payload['expiresAtUtc'] ?? payload['expires_at'] ?? payload['expiresAt'];
    if (expiresAtRaw is String && expiresAtRaw.isNotEmpty) {
      final parsed = DateTime.tryParse(expiresAtRaw)?.toUtc();
      if (parsed != null) return parsed.millisecondsSinceEpoch;
    }

    if (expiresAtRaw is int && expiresAtRaw > 0) {
      // Support seconds and milliseconds epoch formats.
      return expiresAtRaw > 9999999999 ? expiresAtRaw : expiresAtRaw * 1000;
    }

    return null;
  }

  Future<void> _handleErrorCodeSideEffects(int? statusCode) async {
    if (statusCode == 401) {
      await _clearSessionTokens();
    }
  }

  Future<void> _clearSessionTokens() async {
    if (!Hive.isBoxOpen('auth_tokens')) return;

    final box = Hive.box('auth_tokens');
    await box.delete('auth_access_token');
    await box.delete('auth_refresh_token');
    await box.delete('auth_expires_at_utc');
  }

  Duration? _extractRetryAfter(DioException e) {
    final value = e.response?.headers.value('retry-after');
    if (value == null) return null;
    final seconds = int.tryParse(value);
    if (seconds == null) return null;
    return Duration(seconds: seconds);
  }

  /// **🔹 Analytics Event Submission**
  /// Sends a lightweight event to the `/events/:name` endpoint with the given [data].
  /// Useful for custom tracking (e.g., startup, session, screen views).
  Future<void> sendEvent(String name, Map<String, dynamic> data) async {
    await post('/events/$name', body: data);
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    return post('/auth/login', body: {
      'email': email,
      'password': password,
    });
  }

  Future<Map<String, dynamic>> signup({
    required String email,
    required String password,
    Map<String, dynamic>? extra,
  }) async {
    return post('/auth/signup', body: {
      'email': email,
      'password': password,
      if (extra != null) ...extra,
    });
  }

  Future<String?> getOAuthUrl(String provider) async {
    return _handleRequest(() async {
      final response = await _dio.get('/auth/oauth/$provider');
      if (response.data is Map) {
        final data = _asJsonMap(response.data);
        return (data['url'] ?? data['authUrl'] ?? data['redirectUrl'])
            ?.toString();
      }
      if (response.data is String) {
        return response.data as String;
      }
      return null;
    });
  }

  Future<List<SeasonPlayer>> getSeasonLeaderboard(String seasonId) async {
    final response = await get('/seasons/$seasonId/leaderboard');
    final items = response['items'] as List? ?? response['data'] as List? ?? [];
    return items
        .map((item) => SeasonPlayer.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> resetPlayerSeasonPoints(String playerId) async {
    await post('/admin/seasons/reset-player', body: {'playerId': playerId});
  }

  Future<void> scheduleTiebreakerQuiz({
    required List<String> players,
    required DateTime scheduledTime,
  }) async {
    await post('/admin/seasons/schedule-tiebreaker', body: {
      'players': players,
      'scheduledTime': scheduledTime.toIso8601String(),
    });
  }
}
