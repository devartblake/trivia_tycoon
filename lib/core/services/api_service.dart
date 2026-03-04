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

  // Backward-compatible aliases used by some admin call sites.
  int get limit => pageSize;
  int get pages => totalPages;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'items': items,
        'page': page,
        'pageSize': pageSize,
        'limit': limit,
        'total': total,
        'totalPages': totalPages,
        'pages': pages,
        'hasNext': hasNext,
        'hasPrevious': hasPrevious,
      };
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
    connectTimeout: const Duration(seconds: 3),
    receiveTimeout: const Duration(seconds: 3),
    sendTimeout: const Duration(seconds: 3),
  )),
        _refreshDio = Dio(BaseOptions(baseUrl: baseUrl)),
        _configService = ConfigService.instance {

    _attachAuthAndErrorInterceptors();

    // Disable or reduce logging in release mode
    if (_configService.enableLogging && kDebugMode) {
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

  /// Unified API Request Handler with silent timeout handling
  Future<T> _handleRequest<T>(Future<T> Function() request, {bool allowAuthRetry = true}) async {
    try {
      return await request();
    } on DioException catch (e) {
      final isTimeoutLike = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError;

      // Preserve silent timeout/offline behavior while keeping exception type consistent.
      if (isTimeoutLike) {
        if (_configService.enableLogging && kDebugMode) {
          debugPrint("[API Timeout]: ${e.requestOptions.path} - No backend available");
        }

        throw ApiRequestException(
          'API Timeout',
          statusCode: e.response?.statusCode,
          path: e.requestOptions.path,
        );
      }

      final envelope = _extractErrorEnvelope(e.response?.data);
      final retryAfter = _extractRetryAfter(e);
      var normalizedMessage = _extractErrorMessageFromResponse(e, envelope: envelope);

      if (_shouldAttemptRefresh(e, allowAuthRetry)) {
        final refreshed = await _refreshSessionToken();
        if (refreshed) {
          return _handleRequest(request, allowAuthRetry: false);
        }
      }

      if (e.response?.statusCode == 429 && retryAfter != null) {
        normalizedMessage = '$normalizedMessage (retry after ${retryAfter}s)';
      }

      _handleErrorCodeSideEffects(e.response?.statusCode);

      // Log other Dio errors normally
      if (_configService.enableLogging) {
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
      if (_configService.enableLogging) {
        debugPrint("API Error: $e");
      }
      if (e is ApiRequestException) rethrow;
      throw Exception("Unexpected Error: $e");
    }
  }

  String _extractErrorMessageFromResponse(DioException e, {Map<String, dynamic>? envelope}) {
    final responseData = e.response?.data;

    final responseMap = envelope ?? (responseData is Map ? _asJsonMap(responseData) : <String, dynamic>{});
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

  Map<String, String> _buildJsonHeaders(String path, [Map<String, String>? headers]) {
    final resolved = <String, String>{
      'Content-Type': 'application/json',
      if (headers != null) ...headers,
    };

    final hasAuthorization = resolved.keys
        .any((key) => key.toLowerCase() == 'authorization');

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
    final String jsonString = await rootBundle.loadString('assets/data/analytics/$filename');
    return jsonDecode(jsonString);
  }

  Future<Map<String, dynamic>> post(String path,
      {required Map<String, dynamic> body, Map<String, String>? headers}) async {
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
      {Map<String, String>? headers, Map<String, dynamic>? queryParameters}) async {
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
  Future<Map<String, dynamic>> delete(String path, {Map<String, String>? headers}) async {
    return _handleRequest(() async {
      final response = await _dio.delete(
        path,
        options: Options(headers: _buildJsonHeaders(path, headers)),
      );
      return _asJsonMap(response.data);
    });
  }

  Future<Map<String, dynamic>> patch(String path,
      {required Map<String, dynamic> body, Map<String, String>? headers}) async {
    return _handleRequest(() async {
      final response = await _dio.patch(
        path,
        data: body,
        options: Options(headers: _buildJsonHeaders(path, headers)),
      );
      return _asJsonMap(response.data);
    });
  }

  Future<Map<String, dynamic>> put(String path,
      {required Map<String, dynamic> body, Map<String, String>? headers}) async {
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
  ApiPageEnvelope<T> parsePageEnvelope<T>(
    Map<String, dynamic> response, [
    T Function(Map<String, dynamic>)? itemParser,
  ], {
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

    final parser = itemParser ?? (Map<String, dynamic> map) => map as T;

    final items = rawItems.map((item) {
      if (item is Map<String, dynamic>) {
        return parser(item);
      }
      if (item is Map) {
        return parser(_asJsonMap(item));
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

  // Compatibility helpers for branches that still reference these methods.
  bool _isProtectedPath(String path) =>
      path == '/admin' || path.startsWith('/admin/');

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
    return !path.endsWith('/auth/refresh') && !path.endsWith('/admin/auth/refresh');
  }

  Future<bool> _refreshSessionToken() async {
    if (!Hive.isBoxOpen('auth_tokens')) return false;

    final box = Hive.box('auth_tokens');
    final refreshToken = box.get('auth_refresh_token')?.toString() ?? '';
    if (refreshToken.trim().isEmpty) return false;

    try {
      final response = await _dio.post(
        '/admin/auth/refresh',
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
        return false;
      }

      final newRefresh = payload['refreshToken']?.toString() ??
          payload['refresh_token']?.toString() ??
          refreshToken;

      box.put('auth_access_token', access.trim());
      box.put('auth_refresh_token', newRefresh.trim());

      final expiresIn = payload['expiresIn'];
      if (expiresIn is int && expiresIn > 0) {
        final expiresAt = DateTime.now().toUtc().add(Duration(seconds: expiresIn));
        box.put('auth_expires_at_utc', expiresAt.millisecondsSinceEpoch);
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  void _handleErrorCodeSideEffects(int? statusCode) {
    if (statusCode == 401) {
      _clearAccessToken();
    }
  }

  void _clearAccessToken() {
    if (!Hive.isBoxOpen('auth_tokens')) return;
    final box = Hive.box('auth_tokens');
    box.delete('auth_access_token');
  }

  int? _extractRetryAfter(DioException e) {
    final value = e.response?.headers.value('retry-after');
    if (value == null) return null;
    return int.tryParse(value);
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
    throw UnimplementedError('Implement season leaderboard API call');
  }

  Future<void> resetPlayerSeasonPoints(String playerId) async {
    throw UnimplementedError('Implement reset player points API call');
  }

  Future<void> scheduleTiebreakerQuiz({
    required List<String> players,
    required DateTime scheduledTime,
  }) async {
    throw UnimplementedError('Implement tiebreaker quiz scheduling');
  }
}