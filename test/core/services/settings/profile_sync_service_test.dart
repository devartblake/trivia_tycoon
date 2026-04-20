import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/core/services/api_service.dart';
import 'package:trivia_tycoon/core/services/settings/profile_sync_service.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir =
        await Directory.systemTemp.createTemp('profile_sync_service_test');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    ProfileSyncService.resetEndpointBackoffForTests();
    await Hive.openBox('auth_tokens');
  });

  tearDown(() async {
    if (Hive.isBoxOpen('profile_sync_queue')) {
      await Hive.box('profile_sync_queue').clear();
      await Hive.box('profile_sync_queue').close();
      await Hive.deleteBoxFromDisk('profile_sync_queue');
    }
    if (Hive.isBoxOpen('auth_tokens')) {
      await Hive.box('auth_tokens').clear();
      await Hive.box('auth_tokens').close();
      await Hive.deleteBoxFromDisk('auth_tokens');
    }
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('syncProfileUpdate sends auth header and returns confirmed values',
      () async {
    final authBox = Hive.box('auth_tokens');
    await authBox.put('auth_access_token', 'token-abc');

    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    final trackedEvents = <String>[];

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.path, '/users/me');
          expect(options.headers['Authorization'], 'Bearer token-abc');
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'display_name': 'Server Name',
                'username': 'server_user',
              },
            ),
          );
        },
      ),
    );

    final apiService = ApiService(
      baseUrl: 'https://example.test',
      dio: dio,
      initializeCache: false,
    );

    final service = ProfileSyncService(
      apiService: apiService,
      trackEvent: (event, _) async {
        trackedEvents.add(event);
      },
    );

    final result = await service.syncProfileUpdate(
      displayName: 'Local Name',
      username: 'local_user',
    );

    expect(result.synced, isTrue);
    expect(result.queuedForRetry, isFalse);
    expect(result.confirmedDisplayName, 'Server Name');
    expect(result.confirmedUsername, 'server_user');
    expect(trackedEvents, contains('profile_sync_success'));
  });

  test('syncProfileUpdate queues payload when all endpoints fail', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              response: Response(
                requestOptions: options,
                statusCode: 503,
                data: {'message': 'offline'},
              ),
              type: DioExceptionType.badResponse,
            ),
          );
        },
      ),
    );

    final apiService = ApiService(
      baseUrl: 'https://example.test',
      dio: dio,
      initializeCache: false,
    );

    final service = ProfileSyncService(
      apiService: apiService,
      trackEvent: (_, __) async {},
    );

    final result = await service.syncProfileUpdate(
      displayName: 'Local Name',
      username: 'local_user',
    );

    final queueBox = await Hive.openBox('profile_sync_queue');
    expect(result.synced, isFalse);
    expect(result.queuedForRetry, isTrue);
    expect(queueBox.length, 1);
  });

  test('retryQueuedUpdates removes queued item after successful retry',
      () async {
    var attemptCount = 0;
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          attemptCount++;
          if (attemptCount <= 4) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 503,
                  data: {'message': 'offline'},
                ),
                type: DioExceptionType.badResponse,
              ),
            );
            return;
          }

          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {'ok': true},
            ),
          );
        },
      ),
    );

    final apiService = ApiService(
      baseUrl: 'https://example.test',
      dio: dio,
      initializeCache: false,
    );

    final service = ProfileSyncService(
      apiService: apiService,
      trackEvent: (_, __) async {},
    );

    await service.syncProfileUpdate(
      displayName: 'Local Name',
      username: 'local_user',
    );

    final queueBoxBefore = await Hive.openBox('profile_sync_queue');
    expect(queueBoxBefore.length, 1);

    await service.retryQueuedUpdates();

    final queueBoxAfter = await Hive.openBox('profile_sync_queue');
    expect(queueBoxAfter.length, 0);
  });

  test('enqueue de-duplicates identical payloads', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              response: Response(
                requestOptions: options,
                statusCode: 503,
                data: {'message': 'offline'},
              ),
              type: DioExceptionType.badResponse,
            ),
          );
        },
      ),
    );

    final apiService = ApiService(
      baseUrl: 'https://example.test',
      dio: dio,
      initializeCache: false,
    );

    final service = ProfileSyncService(
      apiService: apiService,
      trackEvent: (_, __) async {},
    );

    await service.syncProfileUpdate(
        displayName: 'Same User', username: 'same_user');
    await service.syncProfileUpdate(
        displayName: 'Same User', username: 'same_user');

    final queueBox = await Hive.openBox('profile_sync_queue');
    expect(queueBox.length, 1);
  });

  test('drops queued item after max retry threshold', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              response: Response(
                requestOptions: options,
                statusCode: 503,
                data: {'message': 'offline'},
              ),
              type: DioExceptionType.badResponse,
            ),
          );
        },
      ),
    );

    final events = <String>[];
    final apiService = ApiService(
      baseUrl: 'https://example.test',
      dio: dio,
      initializeCache: false,
    );

    final service = ProfileSyncService(
      apiService: apiService,
      trackEvent: (event, _) async {
        events.add(event);
      },
    );

    await service.syncProfileUpdate(
        displayName: 'Retry User', username: 'retry_user');
    for (var i = 0; i < 11; i++) {
      await service.retryQueuedUpdates();
    }

    final queueBox = await Hive.openBox('profile_sync_queue');
    expect(queueBox.length, 0);
    expect(events, contains('profile_sync_dropped_max_retries'));
  });

  test('getQueueDiagnostics returns queue metadata', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              response: Response(
                requestOptions: options,
                statusCode: 503,
                data: {'message': 'offline'},
              ),
              type: DioExceptionType.badResponse,
            ),
          );
        },
      ),
    );

    final apiService = ApiService(
      baseUrl: 'https://example.test',
      dio: dio,
      initializeCache: false,
    );

    final service = ProfileSyncService(
      apiService: apiService,
      trackEvent: (_, __) async {},
    );

    await service.syncProfileUpdate(
        displayName: 'Diag One', username: 'diag_one');
    await service.syncProfileUpdate(
        displayName: 'Diag Two', username: 'diag_two');

    final diagnostics = await service.getQueueDiagnostics();
    expect(diagnostics['queue_length'], 2);
    expect(diagnostics['max_queue_size'], 100);
    expect(diagnostics['max_retry_count'], 10);
    expect(diagnostics['highest_retry_count'], 0);
    expect(diagnostics['oldest_created_at'], isNotNull);
    expect(diagnostics['newest_created_at'], isNotNull);
  });

  test('syncProfileData generates username when existingUsername is missing',
      () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final body = options.data as Map<String, dynamic>;
          expect(body['username'], 'display_name');
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'display_name': 'Display Name',
                'username': 'display_name',
              },
            ),
          );
        },
      ),
    );

    final apiService = ApiService(
      baseUrl: 'https://example.test',
      dio: dio,
      initializeCache: false,
    );

    final service = ProfileSyncService(
      apiService: apiService,
      trackEvent: (_, __) async {},
    );

    final result = await service.syncProfileData(
      displayName: 'Display Name',
      existingUsername: null,
    );

    expect(result.success, isTrue);
    expect(result.confirmedUsername, 'display_name');
  });

  test('404 marks endpoints in backoff to avoid repeated retry noise',
      () async {
    var requestCount = 0;
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requestCount++;
          handler.reject(
            DioException(
              requestOptions: options,
              response: Response(
                requestOptions: options,
                statusCode: 404,
                data: {'message': 'not found'},
              ),
              type: DioExceptionType.badResponse,
            ),
          );
        },
      ),
    );

    final events = <String>[];
    final apiService = ApiService(
      baseUrl: 'https://example.test',
      dio: dio,
      initializeCache: false,
    );

    final service = ProfileSyncService(
      apiService: apiService,
      trackEvent: (event, _) async => events.add(event),
    );

    await service.syncProfileUpdate(displayName: 'Name', username: 'name');
    final firstCount = requestCount;

    await service.syncProfileUpdate(displayName: 'Name', username: 'name');
    final secondCount = requestCount;

    expect(firstCount, 4); // /users/me, /profile, /user/profile, /auth/profile
    expect(secondCount, firstCount); // skipped due backoff
    expect(events, contains('profile_sync_endpoint_unavailable'));
  });
}
