import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

  ApiRequestException(this.message, {this.statusCode, this.path});

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
}

class ApiService {
  final Dio _dio;
  final String baseUrl;
  late CacheOptions _cacheOptions;
  late final HiveCacheStore _cacheStore;
  late DioCacheInterceptor _cacheInterceptor;
  final ConfigService _configService;

  ApiService({required this.baseUrl})
      : _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    // Shorter timeouts for development to fail fast
    connectTimeout: const Duration(seconds: 3),
    receiveTimeout: const Duration(seconds: 3),
    sendTimeout: const Duration(seconds: 3),
  )),
        _configService = ConfigService.instance {

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

      final normalizedMessage = _extractErrorMessageFromResponse(e);

      // Log other Dio errors normally
      if (ConfigService.enableLogging) {
        debugPrint("API Error [Dio]: $normalizedMessage");
      }

      throw ApiRequestException(
        normalizedMessage,
        statusCode: e.response?.statusCode,
        path: e.requestOptions.path,
      );
    } catch (e) {
      if (ConfigService.enableLogging) {
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

  String? _loadAccessToken() {
    if (!Hive.isBoxOpen('auth_tokens')) return null;
    final box = Hive.box('auth_tokens');
    final token = box.get('auth_access_token')?.toString();
    if (token == null || token.trim().isEmpty) return null;
    return token.trim();
  }

  Map<String, String> _buildJsonHeaders([Map<String, String>? headers]) {
    final resolved = <String, String>{
      'Content-Type': 'application/json',
      if (headers != null) ...headers,
    };

    final hasAuthorization = resolved.keys
        .any((key) => key.toLowerCase() == 'authorization');

    if (!hasAuthorization) {
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

  /// **🔹 Generic POST Request**
  /// Sends a POST request to the specified [path] with a JSON [data] payload.
  /// Handles errors using the unified [_handleRequest] wrapper.
  /// FIX: Returns a type-safe Map for predictable JSON responses.
  Future<Map<String, dynamic>> post(String path,
      {required Map<String, dynamic> body, Map<String, String>? headers}) async {
    return _handleRequest(() async {
      final response = await _dio.post(
        path,
        data: body,
        options: Options(headers: _buildJsonHeaders(headers)),
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
        options: Options(headers: _buildJsonHeaders(headers)),
      );
      return _asJsonMap(response.data);
    });
  }

  /// **🔹 Generic DELETE Request**
  Future<Map<String, dynamic>> delete(String path, {Map<String, String>? headers}) async {
    return _handleRequest(() async {
      final response = await _dio.delete(
        path,
        options: Options(headers: _buildJsonHeaders(headers)),
      );
      return _asJsonMap(response.data);
    });
  }

  /// **🔹 Generic PATCH Request**
  Future<Map<String, dynamic>> patch(String path,
      {required Map<String, dynamic> body, Map<String, String>? headers}) async {
    return _handleRequest(() async {
      final response = await _dio.patch(
        path,
        data: body,
        options: Options(headers: _buildJsonHeaders(headers)),
      );
      return _asJsonMap(response.data);
    });
  }

  /// **🔹 Generic PUT Request**
  Future<Map<String, dynamic>> put(String path,
      {required Map<String, dynamic> body, Map<String, String>? headers}) async {
    return _handleRequest(() async {
      final response = await _dio.put(
        path,
        data: body,
        options: Options(headers: _buildJsonHeaders(headers)),
      );
      return _asJsonMap(response.data);
    });
  }


  /// Parses common paginated envelope variants into a typed structure.
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

  // Compatibility helpers for branches that still reference these methods.
  bool _isProtectedPath(String path) => path.startsWith('/admin/');

  Map<String, dynamic> _extractErrorEnvelope(Object? responseData) {
    if (responseData is Map) {
      final map = _asJsonMap(responseData);
      final nested = _asJsonMap(map['error']);
      return nested.isNotEmpty ? nested : map;
    }
    return <String, dynamic>{};
  }

  bool _shouldAttemptRefresh(DioException e) => e.response?.statusCode == 401;

  Future<bool> _refreshSessionToken() async => false;

  Future<Response<dynamic>> _retryWithFreshToken(DioException e) {
    return _dio.fetch<dynamic>(e.requestOptions);
  }

  void _handleErrorCodeSideEffects(int? statusCode) {}

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
