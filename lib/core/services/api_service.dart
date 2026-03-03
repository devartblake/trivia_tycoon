import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
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

class ApiService {
  final Dio _dio;
  final Dio _refreshDio;
  final String baseUrl;
  late CacheOptions _cacheOptions;
  late final HiveCacheStore _cacheStore;
  late DioCacheInterceptor _cacheInterceptor;
  final ConfigService _configService;
  bool _isRefreshingToken = false;

  ApiService({required this.baseUrl})
      : _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    // Shorter timeouts for development to fail fast
    connectTimeout: const Duration(seconds: 3),
    receiveTimeout: const Duration(seconds: 3),
    sendTimeout: const Duration(seconds: 3),
  )),
        _refreshDio = Dio(BaseOptions(baseUrl: baseUrl)),
        _configService = ConfigService.instance {

    _attachAuthAndErrorInterceptors();

    // Disable or reduce logging in release mode
    if (ConfigService.enableLogging && kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        request: false,           // Disable request logging
        requestHeader: false,      // Disable header logging
        requestBody: false,        // Disable body logging
        responseHeader: false,
        responseBody: false,
        error: true,              // Only log errors
        logPrint: (log) => debugPrint("[API Log]: $log"),
      ));
    }

    _initializeCache();
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

  /// **🔹 Initialize Cache**
  Future<void> _initializeCache() async {
    Directory cacheDir = await getTemporaryDirectory(); // Corrected Cache Directory
    _cacheStore = HiveCacheStore(cacheDir.path); // ✅ Store reference here

    _cacheOptions = CacheOptions(
      store: _cacheStore, // ✅ Uses HiveCacheStore
      policy: CachePolicy.request,
      maxStale: const Duration(days: 7), // Cache expires in 7 days
      hitCacheOnErrorExcept: [], // Cache API errors except for connectivity issues
      priority: CachePriority.high,
    );
    _cacheInterceptor = DioCacheInterceptor(options: _cacheOptions);
    _dio.interceptors.add(_cacheInterceptor);
  }

  /// **🔹 Fetch Questions with Cache**
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

  /// **🔹 Fetch Leaderboard with Cache**
  Future<List<Map<String, dynamic>>> fetchLeaderboard() async {
    return _handleRequest(() async {
      final response = await _dio.get(
        '/leaderboard',
        options: _cacheOptions.toOptions(),
      );
      return List<Map<String, dynamic>>.from(response.data);
    });
  }

  /// **🔹 Fetch Achievements with Cache**
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

  /// **🔹 Submit Score**
  Future<void> submitScore(String playerName, int score) async {
    await _handleRequest(() async {
      await _dio.post('/leaderboard', data: {
        'playerName': playerName,
        'score': score,
      });
    });
  }

  /// **🔹 Unlock Achievement**
  Future<void> unlockAchievement(String playerName, String achievement) async {
    await _handleRequest(() async {
      await _dio.post('/achievements', data: {
        'playerName': playerName,
        'achievement': achievement,
      });
    });
  }

  /// **🔹 Clear Cache Manually**
  Future<void> clearCache() async {
    await _cacheStore.clean();
  }

  /// **🔹 Generic GET Request Handler**
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

  /// Unified API Request Handler with silent timeout handling
  Future<T> _handleRequest<T>(Future<T> Function() request) async {
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

      // Log other Dio errors normally
      if (ConfigService.enableLogging && kDebugMode) {
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

  Duration? _extractRetryAfter(Response<dynamic>? response) {
    final raw = response?.headers.value('retry-after');
    if (raw == null || raw.trim().isEmpty) return null;
    final seconds = int.tryParse(raw.trim());
    if (seconds != null && seconds > 0) {
      return Duration(seconds: seconds);
    }
    return null;
  }

  bool _isProtectedPath(String path) {
    return path.startsWith('/admin/') ||
        path == '/matches/start' ||
        path == '/mobile/matches/start' ||
        path == '/matches/submit' ||
        path == '/matchmaking/enqueue' ||
        path.contains('/party/') && path.endsWith('/enqueue');
  }

  String _loadAccessToken() => _loadTokenByKey('auth_access_token');

  String _loadRefreshToken() => _loadTokenByKey('auth_refresh_token');

  String _loadTokenByKey(String key) {
    if (!Hive.isBoxOpen('auth_tokens')) return '';
    final box = Hive.box('auth_tokens');
    return (box.get(key, defaultValue: '') as String?) ?? '';
  }

  bool _shouldAttemptRefresh(DioException error, ApiErrorEnvelope? envelope) {
    if (_isRefreshingToken) return false;
    final path = error.requestOptions.path;
    if (!path.startsWith('/admin/')) return false;
    if (path == '/admin/auth/login' || path == '/admin/auth/refresh') return false;
    if (error.requestOptions.extra['refreshRetried'] == true) return false;
    return envelope?.code == 'UNAUTHORIZED' || error.response?.statusCode == 401;
  }

  Future<bool> _refreshSessionToken() async {
    final refreshToken = _loadRefreshToken();
    if (refreshToken.isEmpty) return false;

    _isRefreshingToken = true;
    try {
      final response = await _refreshDio.post('/admin/auth/refresh', data: {
        'refreshToken': refreshToken,
      });
      final data = _asJsonMap(response.data);
      final access = data['accessToken']?.toString() ?? data['access_token']?.toString() ?? '';
      if (access.isEmpty) return false;

      if (!Hive.isBoxOpen('auth_tokens')) return false;
      final box = Hive.box('auth_tokens');
      await box.put('auth_access_token', access);
      final newRefresh = data['refreshToken']?.toString() ?? data['refresh_token']?.toString();
      if (newRefresh != null && newRefresh.isNotEmpty) {
        await box.put('auth_refresh_token', newRefresh);
      }
      return true;
    } catch (_) {
      return false;
    } finally {
      _isRefreshingToken = false;
    }
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

  ApiErrorEnvelope? _extractErrorEnvelope(dynamic responseData) {
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

  void _handleErrorCodeSideEffects(RequestOptions options, ApiErrorEnvelope? envelope) {
    if (envelope == null) return;
    if (!ConfigService.enableLogging || !kDebugMode) return;

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

  ApiPageEnvelope<T> parsePageEnvelope<T>(
    Map<String, dynamic> payload,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    final itemsRaw = payload['items'];
    final items = itemsRaw is List
        ? itemsRaw
            .whereType<Map>()
            .map((e) => fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <T>[];
    return ApiPageEnvelope<T>(
      page: (payload['page'] as num?)?.toInt() ?? 1,
      pageSize: (payload['pageSize'] as num?)?.toInt() ?? items.length,
      total: (payload['total'] as num?)?.toInt() ?? items.length,
      items: items,
    );
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

  /// Loads mock data from assets/json
  Future<dynamic> getMockData(String filename) async {
    final String jsonString = await rootBundle.loadString('assets/data/analytics/$filename');
    return jsonDecode(jsonString);
  }

  /// **🔹 Generic POST Request**
  /// Sends a POST request to the specified [path] with a JSON [data] payload.
  /// Handles errors using the unified [_handleRequest] wrapper.
  /// FIX: Returns a type-safe Map for predictable JSON responses.
  Future<Map<String, dynamic>> post(String path,
      {required Map<String, dynamic> body}) async {
    return _handleRequest(() async {
      final response = await _dio.post(
        path,
        data: body,
        options: Options(headers: {
          'Content-Type': 'application/json',
        }),
      );
      // Ensure the response data is a map, otherwise return an empty map.
      return _asJsonMap(response.data);
    });
  }

  /// **🔹 Generic GET Request (JSON map response)**
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _handleRequest(() async {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: Options(headers: {
          'Content-Type': 'application/json',
          if (headers != null) ...headers,
        }),
      );
      return response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : {};
    });
  }

  /// **🔹 Generic DELETE Request**
  Future<Map<String, dynamic>> delete(String path) async {
    return _handleRequest(() async {
      final response = await _dio.delete(
        path,
        options: Options(headers: {
          'Content-Type': 'application/json',
        }),
      );
      return _asJsonMap(response.data);
    });
  }

  /// **🔹 Generic PATCH Request**
  Future<Map<String, dynamic>> patch(String path,
      {required Map<String, dynamic> body}) async {
    return _handleRequest(() async {
      final response = await _dio.patch(
        path,
        data: body,
        options: Options(headers: {
          'Content-Type': 'application/json',
        }),
      );
      return _asJsonMap(response.data);
    });
  }

  /// **🔹 Generic PUT Request**
  Future<Map<String, dynamic>> put(String path,
      {required Map<String, dynamic> body}) async {
    return _handleRequest(() async {
      final response = await _dio.put(
        path,
        data: body,
        options: Options(headers: {
          'Content-Type': 'application/json',
        }),
      );
      return _asJsonMap(response.data);
    });
  }

  /// **🔹 Analytics Event Submission**
  /// Sends a lightweight event to the `/events/:name` endpoint with the given [data].
  /// Useful for custom tracking (e.g., startup, session, screen views).
  Future<void> sendEvent(String name, Map<String, dynamic> data) async {
    await post('/events/$name', body: data);
  }

  /// **🔹 Auth: Login**
  /// Sends credentials to the backend auth endpoint.
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    return post('/auth/login', body: {
      'email': email,
      'password': password,
    });
  }

  /// **🔹 Auth: Signup**
  /// Registers a new user. Additional fields can be passed in [extra].
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

  /// **🔹 Auth: OAuth URL**
  /// Requests the backend-generated OAuth URL for a provider.
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
  final int page;
  final int pageSize;
  final int total;
  final List<T> items;

  const ApiPageEnvelope({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.items,
  });
}

extension SeasonalApiExtensions on ApiService {
  Future<List<SeasonPlayer>> getSeasonLeaderboard(String seasonId) async {
    // Implementation would call your backend
    throw UnimplementedError('Implement season leaderboard API call');
  }

  Future<void> resetPlayerSeasonPoints(String playerId) async {
    // Implementation would reset player's seasonal progress
    throw UnimplementedError('Implement reset player points API call');
  }

  Future<void> scheduleTiebreakerQuiz({
    required List<String> players,
    required DateTime scheduledTime,
  }) async {
    // Implementation would schedule tiebreaker quiz
    throw UnimplementedError('Implement tiebreaker quiz scheduling');
  }
}
