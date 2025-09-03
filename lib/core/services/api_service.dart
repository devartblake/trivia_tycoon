import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'analytics/config_service.dart';

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
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  )),
      _configService = ConfigService.instance {
    if (ConfigService.enableLogging) {
      _dio.interceptors.add(LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
        logPrint: (log) => debugPrint("[API Log]: $log"),
      ));
    }

    /// **🔹 Initialize Cache**
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
        '/questions',
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

  /// **🔹 Unified API Request Handler**
  Future<T> _handleRequest<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      if (ConfigService.enableLogging) {
        debugPrint("API Error [Dio]: ${e.message}");
      }
      throw Exception("API Error: ${e.message}");
    } catch (e) {
      if (ConfigService.enableLogging) {
        debugPrint("API Error: $e");
      }
      throw Exception("Unexpected Error: $e");
    }
  }

  /// Loads mock data from assets/json
  Future<dynamic> getMockData(String filename) async {
    final String jsonString = await rootBundle.loadString('assets/data/analytics/$filename');
    return jsonDecode(jsonString);
  }

  /// **🔹 Generic POST Request**
  /// Sends a POST request to the specified [path] with a JSON [data] payload.
  /// Handles errors using the unified [_handleRequest] wrapper.
  Future<void> post(String path, {required Map<String, dynamic> data}) async {
    await _handleRequest(() async {
      await _dio.post(
        path,
        data: data,
        options: Options(headers: {
          'Content-Type': 'application/json',
        }),
      );
    });
  }

  /// **🔹 Analytics Event Submission**
  /// Sends a lightweight event to the `/events/:name` endpoint with the given [data].
  /// Useful for custom tracking (e.g., startup, session, screen views).
  Future<void> sendEvent(String name, Map<String, dynamic> data) async {
    await post('/events/$name', data: data);
  }
}
