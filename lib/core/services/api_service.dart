import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import '../../game/models/seasonal_competition_model.dart';
import 'analytics/config_service.dart';

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

class ApiErrorEnvelope {
  final String code;
  final String message;
  final Map<String, dynamic> details;

  const ApiErrorEnvelope({
    required this.code,
    required this.message,
    required this.details,
  });
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
}

class ApiService {
  final Dio _dio;
  final Dio _refreshDio;
  final String baseUrl;
  late CacheOptions _cacheOptions;
  late final HiveCacheStore _cacheStore;
  late DioCacheInterceptor _cacheInterceptor;
  final ConfigService _configService;
  bool _isRefreshingToken = false;

  ApiService({
    required this.baseUrl,
    Dio? dio,
    ConfigService? configService,
    bool initializeCache = true,
  })
      : _dio = dio ?? Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 3),
    receiveTimeout: const Duration(seconds: 3),
    sendTimeout: const Duration(seconds: 3),
  )),
        _refreshDio = Dio(BaseOptions(baseUrl: baseUrl)),
        _configService = ConfigService.instance {
    _attachAuthAndErrorInterceptors();

    if (ConfigService.enableLogging && kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        request: false,
        requestHeader: false,
        requestBody: false,
        responseHeader: false,
        responseBody: false,
        error: true,
        logPrint: (log) => debugPrint("[API Log]: $log"),
      ));
    }

    if (initializeCache) {
      _initializeCache();
    }
  }

  void _attachAuthAndErrorInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final path = options.path;
          if (_isProtectedPath(path)) {
            final token = _loadAccessToken();
            if (token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            final opsKey = dotenv.env['ADMIN_OPS_KEY'];
            if (path.startsWith('/admin/') && opsKey != null && opsKey.isNotEmpty) {
              options.headers['x-ops-key'] = opsKey;
            }
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final envelope = _extractErrorEnvelope(error.response?.data);

          if (_shouldAttemptRefresh(error, envelope) && await _refreshSessionToken()) {
            final retried = await _retryWithFreshToken(error.requestOptions);
            if (retried != null) {
              return handler.resolve(retried);
            }
          }

          _handleErrorCodeSideEffects(error.requestOptions, envelope);
          handler.next(error);
        },
      ),
    );
  }

  Future<void> _initializeCache() async {
    Directory cacheDir = await getTemporaryDirectory();
    _cacheStore = HiveCacheStore(cacheDir.path);

    _cacheOptions = CacheOptions(
      store: _cacheStore,
      policy: CachePolicy.request,
      maxStale: const Duration(days: 7),
      hitCacheOnErrorExcept: [],
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

  Future<List<Map<String, dynamic>>> fetchLeaderboard() async {
    return _handleRequest(() async {
      final response = await _dio.get(
        '/leaderboard',
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
      final response = await http.get(Uri.parse('$baseUrl/$endpoint'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Error: ${response.statusCode}");
      }
    });
  }

  Future<T> _handleRequest<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      final isTimeoutLike = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError;

      if (isTimeoutLike) {
        if (ConfigService.enableLogging && kDebugMode) {
          debugPrint("[API Timeout]: ${e.requestOptions.path} - No backend available");
        }

        throw ApiRequestException(
          'API Timeout',
          statusCode: e.response?.statusCode,
          path: e.requestOptions.path,
        );
      }

      final envelope = _extractErrorEnvelope(e.response?.data);
      final normalizedMessage = envelope?.message ?? _extractErrorMessageFromResponse(e);

      if (ConfigService.enableLogging) {
        debugPrint("API Error [Dio]: $normalizedMessage");
      }

      throw ApiRequestException(
        normalizedMessage,
        statusCode: e.response?.statusCode,
        path: e.requestOptions.path,
        errorCode: envelope?.code,
        details: envelope?.details,
        retryAfter: _extractRetryAfter(e.response),
      );
    } catch (e) {
      if (ConfigService.enableLogging && kDebugMode) {
        debugPrint("API Error: $e");
      }
      if (e is ApiRequestException) rethrow;
      throw Exception("Unexpected Error: $e");
    }
  }

  String _extractErrorMessageFromResponse(DioException e) {
    final responseData = e.response?.data;

    if (responseData is Map) {
      final responseMap = _asJsonMap(responseData);
      final nestedError = responseData['error'];
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

  String _loadAccessToken() {
    if (!Hive.isBoxOpen('auth_tokens')) return '';
    final box = Hive.box('auth_tokens');
    final token = box.get('auth_access_token')?.toString();
    if (token == null || token.trim().isEmpty) return '';
    return token.trim();
  }

  String _loadRefreshToken() {
    if (!Hive.isBoxOpen('auth_tokens')) return '';
    final box = Hive.box('auth_tokens');
    return (box.get('auth_refresh_token', defaultValue: '') as String?) ?? '';
  }

  Map<String, String> _buildJsonHeaders([Map<String, String>? headers]) {
    final resolved = <String, String>{
      'Content-Type': 'application/json',
      if (headers != null) ...headers,
    };

    final hasAuthorization = resolved.keys.any((key) => key.toLowerCase() == 'authorization');

    if (!hasAuthorization) {
      final accessToken = _loadAccessToken();
      if (accessToken.isNotEmpty) {
        resolved['Authorization'] = 'Bearer $accessToken';
      }
    }

    return resolved;
  }

  Future<dynamic> getMockData(String filename) async {
    final String jsonString = await rootBundle.loadString('assets/data/analytics/$filename');
    return jsonDecode(jsonString);
  }

  Future<Map<String, dynamic>> post(
      String path, {
        required Map<String, dynamic> body,
        Map<String, String>? headers,
      }) async {
    return _handleRequest(() async {
      final response = await _dio.post(
        path,
        data: body,
        options: Options(headers: _buildJsonHeaders(headers)),
      );
      return _asJsonMap(response.data);
    });
  }

  Future<Map<String, dynamic>> get(
      String path, {
        Map<String, String>? headers,
        Map<String, dynamic>? queryParameters,
      }) async {
    return _handleRequest(() async {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: Options(headers: _buildJsonHeaders(headers)),
      );
      return _asJsonMap(response.data);
    });
  }

  Future<Map<String, dynamic>> delete(
      String path, {
        Map<String, String>? headers,
      }) async {
    return _handleRequest(() async {
      final response = await _dio.delete(
        path,
        options: Options(headers: _buildJsonHeaders(headers)),
      );
      return _asJsonMap(response.data);
    });
  }

  Future<Map<String, dynamic>> patch(
      String path, {
        required Map<String, dynamic> body,
        Map<String, String>? headers,
      }) async {
    return _handleRequest(() async {
      final response = await _dio.patch(
        path,
        data: body,
        options: Options(headers: _buildJsonHeaders(headers)),
      );
      return _asJsonMap(response.data);
    });
  }

  Future<Map<String, dynamic>> put(
      String path, {
        required Map<String, dynamic> body,
        Map<String, String>? headers,
      }) async {
    return _handleRequest(() async {
      final response = await _dio.put(
        path,
        data: body,
        options: Options(headers: _buildJsonHeaders(headers)),
      );
      return _asJsonMap(response.data);
    });
  }

  ApiPageEnvelope<T> parsePageEnvelope<T>(
      Map<String, dynamic> response,
      T Function(Map<String, dynamic>) itemParser, {
        List<String> dataKeys = const ['items', 'data', 'results', 'rows'],
      }) {
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

    final items = rawItems.map((item) {
      if (item is Map<String, dynamic>) {
        return itemParser(item);
      }
      if (item is Map) {
        return itemParser(_asJsonMap(item));
      }
      throw ApiRequestException('Invalid paginated item type: ${item.runtimeType}');
    }).toList(growable: false);

    return ApiPageEnvelope<T>(
      items: items,
      page: page,
      pageSize: pageSize,
      total: total,
      totalPages: totalPages,
    );
  }

  bool _isProtectedPath(String path) {
    return path.startsWith('/admin/') ||
        path == '/matches/start' ||
        path == '/mobile/matches/start' ||
        path == '/matches/submit' ||
        path == '/matchmaking/enqueue' ||
        path.contains('/party/') && path.endsWith('/enqueue');
  }

  ApiErrorEnvelope? _extractErrorEnvelope(Object? responseData) {
    if (responseData is! Map) return null;
    final root = _asJsonMap(responseData);
    final nested = root['error'];
    if (nested is! Map) return null;
    final error = _asJsonMap(nested);
    final code = error['code']?.toString();
    final message = error['message']?.toString();
    final details = error['details'] is Map ? _asJsonMap(error['details']) : <String, dynamic>{};
    if (code == null || message == null || code.isEmpty || message.isEmpty) return null;
    return ApiErrorEnvelope(code: code, message: message, details: details);
  }

  bool _shouldAttemptRefresh(DioException error, ApiErrorEnvelope? envelope) {
    if (_isRefreshingToken) return false;
    final path = error.requestOptions.path;
    if (!path.startsWith('/admin/')) return false;
    if (path == '/admin/auth/login' || path == '/admin/auth/refresh') return false;
    if (error.requestOptions.extra['refreshRetried'] == true) return false;
    return envelope?.code == 'UNAUTHORIZED' || error.response?.statusCode == 401;
  }

  // Enhanced refresh with multiple endpoint support and better token expiry handling
  Future<bool> _refreshSessionToken() async {
    final refreshToken = _loadRefreshToken();
    if (refreshToken.isEmpty) return false;

    _isRefreshingToken = true;

    // Try both admin and regular auth refresh endpoints
    const refreshPaths = ['/admin/auth/refresh', '/auth/refresh'];

    for (final refreshPath in refreshPaths) {
      try {
        final response = await _refreshDio.post(
          refreshPath,
          data: {
            'refreshToken': refreshToken,
            'refresh_token': refreshToken,
          },
        );

        final payload = _asJsonMap(response.data);
        final access = payload['accessToken']?.toString() ??
            payload['access_token']?.toString() ??
            '';

        if (access.trim().isEmpty) {
          continue; // Try next endpoint
        }

        final newRefresh = payload['refreshToken']?.toString() ??
            payload['refresh_token']?.toString() ??
            refreshToken;

        if (!Hive.isBoxOpen('auth_tokens')) {
          _isRefreshingToken = false;
          return false;
        }

        final box = Hive.box('auth_tokens');
        await box.put('auth_access_token', access.trim());
        await box.put('auth_refresh_token', newRefresh.trim());

        // ✅ NEW: Better expiry handling
        final expiresAtEpochMs = _resolveExpiryEpochMs(payload);
        if (expiresAtEpochMs != null) {
          await box.put('auth_expires_at_utc', expiresAtEpochMs);
        } else {
          await box.delete('auth_expires_at_utc');
        }

        _isRefreshingToken = false;
        return true;
      } on DioException catch (e) {
        final statusCode = e.response?.statusCode;
        if (statusCode == 401 || statusCode == 403) {
          // Invalid refresh token - clear session
          await _clearSessionTokens();
          _isRefreshingToken = false;
          return false;
        }
        // Try the next refresh endpoint variant
      } catch (_) {
        // Try the next refresh endpoint variant
      }
    }

    _isRefreshingToken = false;
    return false;
  }

  // Smart expiry resolution from multiple payload formats
  int? _resolveExpiryEpochMs(Map<String, dynamic> payload) {
    // Try expiresIn (seconds from now)
    final expiresInRaw = payload['expiresIn'] ?? payload['expires_in'];
    final expiresIn = expiresInRaw is int
        ? expiresInRaw
        : (expiresInRaw is String ? int.tryParse(expiresInRaw) : null);

    if (expiresIn != null && expiresIn > 0) {
      return DateTime.now().toUtc().add(Duration(seconds: expiresIn)).millisecondsSinceEpoch;
    }

    // Try expiresAt (absolute timestamp)
    final expiresAtRaw = payload['expiresAtUtc'] ?? payload['expires_at'] ?? payload['expiresAt'];

    if (expiresAtRaw is String && expiresAtRaw.isNotEmpty) {
      final parsed = DateTime.tryParse(expiresAtRaw)?.toUtc();
      if (parsed != null) return parsed.millisecondsSinceEpoch;
    }

    if (expiresAtRaw is int && expiresAtRaw > 0) {
      // Support both seconds and milliseconds epoch formats
      return expiresAtRaw > 9999999999 ? expiresAtRaw : expiresAtRaw * 1000;
    }

    return null;
  }

  Future<Response<dynamic>?> _retryWithFreshToken(RequestOptions requestOptions) async {
    try {
      final opts = Options(
        method: requestOptions.method,
        headers: Map<String, dynamic>.from(requestOptions.headers)
          ..['Authorization'] = 'Bearer ${_loadAccessToken()}',
        extra: Map<String, dynamic>.from(requestOptions.extra)..['refreshRetried'] = true,
      );
      return _dio.request<dynamic>(
        requestOptions.path,
        data: requestOptions.data,
        queryParameters: requestOptions.queryParameters,
        options: opts,
      );
    } catch (_) {
      return null;
    }
  }

  void _handleErrorCodeSideEffects(RequestOptions options, ApiErrorEnvelope? envelope) {
    if (envelope == null) return;
    if (!ConfigService.enableLogging) return;

    final path = options.path;
    final matchId = options.data is Map ? (options.data as Map)['matchId'] : null;
    final userId = options.data is Map
        ? (options.data as Map)['userId'] ?? (options.data as Map)['adminUserId']
        : null;

    debugPrint(
      '[API Telemetry] endpoint=$path errorCode=${envelope.code} '
          'matchId=${matchId ?? '-'} userId=${userId ?? '-'}',
    );

    switch (envelope.code) {
      case 'UNAUTHORIZED':
        debugPrint('[API:$path] UNAUTHORIZED -> trigger reauth/session recovery');
        break;
      case 'FORBIDDEN':
        debugPrint('[API:$path] FORBIDDEN -> show permission denied UI');
        break;
      case 'RATE_LIMITED':
        debugPrint('[API:$path] RATE_LIMITED -> disable actions + cooldown timer');
        break;
      case 'VALIDATION_ERROR':
        debugPrint('[API:$path] VALIDATION_ERROR -> map details to form errors');
        break;
      case 'NOT_FOUND':
        debugPrint('[API:$path] NOT_FOUND -> stale resource/list refresh');
        break;
      case 'CONFLICT':
        debugPrint('[API:$path] CONFLICT -> refresh state + conflict UI');
        break;
    }
  }

  // Clear session tokens helper
  Future<void> _clearSessionTokens() async {
    if (!Hive.isBoxOpen('auth_tokens')) return;
    final box = Hive.box('auth_tokens');
    await box.delete('auth_access_token');
    await box.delete('auth_refresh_token');
    await box.delete('auth_expires_at_utc');
  }

  Duration? _extractRetryAfter(Response<dynamic>? response) {
    final raw = response?.headers.value('retry-after');
    if (raw == null || raw.trim().isEmpty) return null;
    final seconds = int.tryParse(raw.trim());
    if (seconds != null && seconds > 0) {
      return Duration(seconds: seconds);
    }
    return null;
  }

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
        return (data['url'] ?? data['authUrl'] ?? data['redirectUrl'])?.toString();
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
    return items.map((item) => SeasonPlayer.fromJson(item as Map<String, dynamic>)).toList();
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