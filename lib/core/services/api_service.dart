import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import '_api_cache_store.dart' if (dart.library.io) '_api_cache_store_io.dart';
import 'package:synaptix/core/env.dart';
import '../dto/champion_round_events.dart';
import '../../game/models/champion_event.dart';
import '../../game/models/season_tiebreaker.dart';
import '../../game/models/seasonal_competition_model.dart';
import 'analytics/config_service.dart';
import 'package:synaptix/core/manager/log_manager.dart';
import 'package:synaptix/core/services/asset_resolver.dart';
import 'package:synaptix/core/services/guest_api_gate.dart';


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

class FeatureDisabledException implements Exception {
  final String feature;
  final String message;

  const FeatureDisabledException(
      {required this.feature, required this.message});

  @override
  String toString() => 'FeatureDisabledException[$feature]: $message';
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

  /// Callback when auth tokens are cleared due to 401/refresh failure.
  final Future<void> Function()? onAuthCleared;

  /// Prefer live tokens from [AuthTokenStore] once ServiceManager finishes boot.
  static String? Function()? accessTokenProvider;

  static void bindAccessTokenProvider(String? Function()? provider) {
    accessTokenProvider = provider;
  }

  ApiService({
    required this.baseUrl,
    Dio? dio,
    Dio? refreshDio,
    ConfigService? configService,
    bool initializeCache = true,
    this.onAuthCleared,
  })  : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: EnvConfig.apiConnectTimeout,
              receiveTimeout: EnvConfig.apiReceiveTimeout,
              // sendTimeout is unsupported on web (Dio has no body to send for GET/DELETE)
              sendTimeout: kIsWeb ? null : EnvConfig.apiSendTimeout,
            )),
        _refreshDio = refreshDio ??
            dio ??
            Dio(BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: EnvConfig.apiConnectTimeout,
              receiveTimeout: EnvConfig.apiRefreshReceiveTimeout,
            )) {
    // Guest / unauthenticated gate — short-circuit before network I/O.
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Prefer Dio's composed URI; fall back to path-only for unit tests.
        final uri = options.uri;
        final hasToken = (_loadAccessToken() ?? '').isNotEmpty;
        if (GuestApiGate.shouldBlockNetworkRequest(
          uri,
          hasAuthTokens: hasToken,
        )) {
          LogManager.debug(
              '[ApiService] Guest gate blocked ${options.method} ${options.path}');
          return handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.badResponse,
              response: Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 401,
                data: GuestApiGate.blockedBody(path: options.path),
                statusMessage: 'Guest mode — network blocked',
              ),
              error: GuestApiGate.blockedErrorCode,
              message: 'Guest mode — network blocked',
            ),
          );
        }
        return handler.next(options);
      },
    ));

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

  @Deprecated('Use QuestionHubService or StudyService instead. '
      'Direct question fetching is handled by /questions endpoints.')
  Future<List<Map<String, dynamic>>> fetchQuestions({
    required int amount,
    String? category,
    String? difficulty,
  }) async {
    return _handleRequest(() async {
      final response = await _dio.get(
        '/questions/set',
        queryParameters: {
          'count': amount,
          if (category != null) 'category': category,
          if (difficulty != null) 'difficulty': difficulty,
        },
        options: _cacheOptions.toOptions(),
      );
      final body = response.data;
      final items = body is List
          ? body
          : (body is Map
              ? body['questions'] ?? body['items'] ?? const []
              : const []);
      return List<Map<String, dynamic>>.from(items);
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

  /// Fetches achievements. With a [playerId] (GUID) the player's unlocked
  /// achievements are returned (GET /achievements/player/{id}); without one,
  /// the full catalog (GET /achievements). Both verified against
  /// AchievementsEndpoints.cs — the old ?playerName= query never existed.
  Future<List<Map<String, dynamic>>> fetchAchievements({
    String? playerId,
  }) async {
    return _handleRequest(() async {
      final path = (playerId != null && playerId.isNotEmpty)
          ? '/achievements/player/$playerId'
          : '/achievements';
      final response = await _dio.get(
        path,
        options: _cacheOptions.toOptions(),
      );
      final data = response.data;
      final items = data is List
          ? data
          : (data is Map ? data['items'] ?? const [] : const []);
      return List<Map<String, dynamic>>.from(items);
    });
  }

  @Deprecated('The backend has no POST /leaderboard. Scores enter the '
      'leaderboard server-side via POST /quiz/complete and '
      'POST /leaderboards/arcade/submit; this call always fails.')
  Future<void> submitScore(String playerName, int score) async {
    await _handleRequest(() async {
      await _dio.post('/leaderboard', data: {
        'playerName': playerName,
        'score': score,
      });
    });
  }

  /// POST /quiz/complete (verified against QuizEndpoints.cs). Requires auth;
  /// [playerId] and [eventId] must be GUIDs and match the JWT player, and
  /// answers items must be {questionId, selectedOptionId}. NOTE: this
  /// endpoint awards XP/coins server-side and so does the quizSessionId path
  /// on POST /questions/check-batch — a quiz run must use one or the other,
  /// never both, or the player is double-credited.
  Future<void> submitQuizComplete({
    required String eventId,
    required String playerId,
    required int score,
    required int totalQuestions,
    required String category,
    required List<Map<String, dynamic>> answers,
  }) async {
    await _handleRequest(() async {
      await _dio.post('/quiz/complete', data: {
        'eventId': eventId,
        'playerId': playerId,
        'score': score,
        'totalQuestions': totalQuestions,
        'category': category,
        'answers': answers,
      });
    });
  }

  /// POST /achievements/unlock (verified against AchievementsEndpoints.cs).
  /// [playerId] is the player's GUID; [achievementKey] the catalog key.
  Future<void> unlockAchievement(String playerId, String achievementKey) async {
    await _handleRequest(() async {
      await _dio.post('/achievements/unlock', data: {
        'playerId': playerId,
        'achievementKey': achievementKey,
      });
    });
  }

  Future<Map<String, dynamic>> fetchAppConfig() async {
    return _handleRequest(() async {
      final response = await _dio.get('/app/config');
      final data = response.data;
      return data is Map<String, dynamic> ? data : <String, dynamic>{};
    });
  }

  Future<void> clearCache() async {
    await _cacheStore.clean();
  }

  Options _buildJsonOptions(
    String path,
    Map<String, String>? headers, {
    Duration? timeout,
  }) {
    return Options(
      headers: _buildJsonHeaders(path, headers),
      // sendTimeout is unsupported on web
      sendTimeout: kIsWeb ? null : timeout,
      receiveTimeout: timeout,
    );
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

      if (e.response?.statusCode == 403) {
        final errorCode =
            envelope['error']?.toString() ?? envelope['code']?.toString();
        if (errorCode == 'FeatureDisabled') {
          throw FeatureDisabledException(
            feature: envelope['feature']?.toString() ?? 'unknown',
            message: envelope['message']?.toString() ??
                'This feature is not available in the current release.',
          );
        }
      }

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
      if (e is FeatureDisabledException) rethrow;
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
    final fromProvider = accessTokenProvider?.call();
    if (fromProvider != null && fromProvider.trim().isNotEmpty) {
      return fromProvider.trim();
    }

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
        await AssetResolver.instance.loadString('analytics/$filename');
    return jsonDecode(jsonString);
  }

  /// **🔹 Generic POST Request**
  /// Sends a POST request to the specified [path] with a JSON [data] payload.
  /// Handles errors using the unified [_handleRequest] wrapper.
  /// FIX: Returns a type-safe Map for predictable JSON responses.
  Future<Map<String, dynamic>> post(String path,
      {required Map<String, dynamic> body,
      Map<String, String>? headers,
      Duration? timeout}) async {
    return _handleRequest(() async {
      final response = await _dio.post(
        path,
        data: body,
        options: _buildJsonOptions(path, headers, timeout: timeout),
      );
      // Ensure the response data is a map, otherwise return an empty map.
      return _asJsonMap(response.data);
    });
  }

  /// **🔹 Generic GET Request (JSON map response)**
  Future<Map<String, dynamic>> get(String path,
      {Map<String, String>? headers,
      Map<String, dynamic>? queryParameters,
      Duration? timeout}) async {
    return _handleRequest(() async {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: _buildJsonOptions(path, headers, timeout: timeout),
      );
      return _asJsonMap(response.data);
    });
  }

  /// **🔹 Generic DELETE Request**
  Future<Map<String, dynamic>> delete(String path,
      {Map<String, dynamic>? body,
      Map<String, String>? headers,
      Duration? timeout}) async {
    return _handleRequest(() async {
      final response = await _dio.delete(
        path,
        data: body,
        options: _buildJsonOptions(path, headers, timeout: timeout),
      );
      return _asJsonMap(response.data);
    });
  }

  /// Generic GET request for endpoints that return a JSON array.
  Future<List<Map<String, dynamic>>> getList(String path,
      {Map<String, String>? headers,
      Map<String, dynamic>? queryParameters,
      Duration? timeout}) async {
    return _handleRequest(() async {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: _buildJsonOptions(path, headers, timeout: timeout),
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
      Map<String, String>? headers,
      Duration? timeout}) async {
    return _handleRequest(() async {
      final response = await _dio.patch(
        path,
        data: body,
        options: _buildJsonOptions(path, headers, timeout: timeout),
      );
      return _asJsonMap(response.data);
    });
  }

  /// **🔹 Generic PUT Request**
  Future<Map<String, dynamic>> put(String path,
      {required Map<String, dynamic> body,
      Map<String, String>? headers,
      Duration? timeout}) async {
    return _handleRequest(() async {
      final response = await _dio.put(
        path,
        data: body,
        options: _buildJsonOptions(path, headers, timeout: timeout),
      );
      return _asJsonMap(response.data);
    });
  }

  /// Parses common paginated envelope variants into a typed structure.
  /// Supports optional itemParser as second positional parameter.
  ApiPageEnvelope<T> parsePageEnvelope<T>(Map<String, dynamic> response,
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
    if (path == '/rewards' || path.startsWith('/rewards/')) return true;
    if (path == '/spins' || path.startsWith('/spins/')) return true;
    if (path == '/arcade' || path.startsWith('/arcade/')) return true;
    if (path == '/missions' || path.startsWith('/missions/')) return true;

    // Backend requires authorization for these features (see
    // docs/api/BACKEND_API_AUDIT.md); without the bearer header they 401.
    if (path == '/matches' || path.startsWith('/matches/')) return true;
    // Game-event entry / live-round answers are player-scoped (JWT).
    if (path == '/game-events' || path.startsWith('/game-events/')) return true;
    if (path == '/party' || path.startsWith('/party/')) return true;
    if (path == '/progression' || path.startsWith('/progression/')) {
      return true;
    }
    if (path == '/account' || path.startsWith('/account/')) return true;

    // Tiebreakers are caller-scoped; the leaderboard is public but returns
    // the caller's own off-page rank ("me") when a bearer token is present.
    if (path.startsWith('/seasons/') &&
        (path.contains('/tiebreakers') || path.endsWith('/leaderboard'))) {
      return true;
    }

    // User-scoped/profile endpoints also require auth headers and token refresh handling.
    if (path == '/users/me' || path.startsWith('/users/me/')) return true;
    if (path == '/users/search' || path.startsWith('/users/search/')) {
      return true;
    }
    if (path == '/friends' || path.startsWith('/friends/')) return true;
    if (path == '/profile' || path.startsWith('/profile/')) return true;
    if (path == '/auth/profile' || path.startsWith('/auth/profile/')) {
      return true;
    }
    if (path == '/user/profile' || path.startsWith('/user/profile/')) {
      return true;
    }

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

    // User refresh first: regular players are the overwhelming majority, and
    // trying the admin variant first cost every user a failed request.
    const refreshPaths = ['/auth/refresh', '/admin/auth/refresh'];

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

    final expiresAtRaw = payload['expiresAtUtc'] ??
        payload['expires_at'] ??
        payload['expiresAt'];
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
    if (onAuthCleared != null) {
      await onAuthCleared!();
    }

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
  /// Sends a lightweight event to POST /analytics/events (verified against
  /// AnalyticsEndpoints.cs — the old /events/{name} route never existed).
  /// The endpoint accepts a single event object or an array of them.
  Future<void> sendEvent(String name, Map<String, dynamic> data) async {
    await post('/analytics/events', body: {
      'type': name,
      ...data,
    });
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

  static final RegExp _guidPattern = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

  /// **🔹 Season Leaderboard**
  /// GET /seasons/{seasonId}/leaderboard — rank-point standings for a season
  /// (closed seasons serve the immutable end-of-season snapshot). The backend
  /// only knows seasons by GUID; legacy locally generated ids
  /// (`season_<millis>`) fall back to the active season's leaderboard.
  Future<List<SeasonPlayer>> getSeasonLeaderboard(
    String seasonId, {
    int page = 1,
    int pageSize = 50,
  }) async {
    final path = _guidPattern.hasMatch(seasonId)
        ? '/seasons/$seasonId/leaderboard'
        : '/seasons/active/leaderboard';
    final response = await get(path, queryParameters: {
      'page': page,
      'pageSize': pageSize,
    });
    final items = response['items'] as List? ?? [];
    return items
        .map((item) => SeasonPlayer.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// **🔹 My Season Tiebreakers**
  /// GET /seasons/tiebreakers/mine — the authenticated player's pending
  /// end-of-season tie-breakers. Detection, scheduling and resolution are
  /// server-side; the client only surfaces them and deep-links into the
  /// match flow (mode 'tiebreaker').
  ///
  /// Replaces the old client-driven `resetPlayerSeasonPoints` /
  /// `scheduleTiebreakerQuiz` methods, which called routes that never
  /// existed — resets happen at season close (carryover) or via the admin
  /// moderation route, and tiebreakers are scheduled by the backend when a
  /// season closes with a contested rank.
  Future<List<SeasonTiebreaker>> getMyTiebreakers() async {
    final response = await get('/seasons/tiebreakers/mine');
    final items = response['items'] as List? ?? [];
    return items
        .map((item) => SeasonTiebreaker.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// **🔹 Upcoming Game Events**
  /// GET /game-events/upcoming — scheduled/open/live events, optionally
  /// filtered to a tier. Used to surface the weekly Champion vs Tier event.
  Future<List<ChampionEvent>> getUpcomingGameEvents({int? tierId}) async {
    return _handleRequest(() async {
      // The endpoint returns a bare JSON array, so read the Dio body directly
      // (the generic get() helper coerces non-map bodies to an empty map).
      final response = await _dio.get(
        '/game-events/upcoming',
        queryParameters: {if (tierId != null) 'tierId': tierId},
        options: _buildJsonOptions('/game-events/upcoming', null),
      );
      final data = response.data;
      final list = data is List
          ? data
          : (data is Map ? (data['data'] ?? data['items']) as List? : null) ??
              const [];
      return list.map((e) => ChampionEvent.fromJson(_asJsonMap(e))).toList();
    });
  }

  /// **🔹 Game Event Status**
  /// GET /game-events/{id} — full status incl. jackpot, champion, alive count.
  Future<ChampionEvent> getGameEventStatus(String gameEventId) async {
    final response = await get('/game-events/$gameEventId');
    return ChampionEvent.fromJson(response);
  }

  /// **🔹 Enter Game Event**
  /// POST /game-events/enter — join an open event (debits the entry fee).
  /// [eventId] is a client-minted idempotency key for the entry.
  Future<String> enterGameEvent({
    required String eventId,
    required String gameEventId,
    required String playerId,
  }) async {
    final response = await post('/game-events/enter', body: {
      'eventId': eventId,
      'gameEventId': gameEventId,
      'playerId': playerId,
    });
    return response['status']?.toString() ?? 'Unknown';
  }

  /// **🔹 Submit Live Round Answer**
  /// POST /game-events/{id}/rounds/answer — answer the current live round of a
  /// Champion vs Tier match. The backend derives the player from the JWT.
  Future<String> submitRoundAnswer({
    required String gameEventId,
    required String optionId,
  }) async {
    final response = await post(
      '/game-events/$gameEventId/rounds/answer',
      body: {'optionId': optionId},
    );
    return response['status']?.toString() ?? 'Unknown';
  }

  /// **🔹 Live Match Snapshot (replay-on-join)**
  /// GET /game-events/{id}/live — the current open round/duel so a client
  /// entering mid-match renders live state immediately.
  Future<ChampionLiveSnapshotDto?> getLiveSnapshot(String gameEventId) async {
    try {
      final response = await get('/game-events/$gameEventId/live');
      if (response.isEmpty) return null;
      return ChampionLiveSnapshotDto.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  /// **🔹 Live Match Roster**
  /// GET /game-events/{id}/participants — players with handles + champion /
  /// eliminated flags, for the champion's duel picker and the mob view.
  Future<List<ChampionParticipant>> getEventParticipants(
      String gameEventId) async {
    try {
      final response = await get('/game-events/$gameEventId/participants');
      final items = response['participants'] as List? ?? const [];
      return items
          .map((e) => ChampionParticipant.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// **🔹 Start a Champion Duel**
  /// POST /game-events/{id}/duel — the champion calls out a challenger.
  Future<String> startChampionDuel({
    required String gameEventId,
    required String challengerPlayerId,
  }) async {
    final response = await post(
      '/game-events/$gameEventId/duel',
      body: {'challengerPlayerId': challengerPlayerId},
    );
    return response['status']?.toString() ?? 'Unknown';
  }

  /// **🔹 Submit a Duel Answer**
  /// POST /game-events/{id}/duel/answer — either duelist answers.
  Future<String> submitDuelAnswer({
    required String gameEventId,
    required String optionId,
  }) async {
    final response = await post(
      '/game-events/$gameEventId/duel/answer',
      body: {'optionId': optionId},
    );
    return response['status']?.toString() ?? 'Unknown';
  }
}
