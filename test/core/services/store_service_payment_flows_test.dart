import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/core/services/api_service.dart';
import 'package:trivia_tycoon/core/services/store/store_service.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'store_service_payment_flows_test',
    );
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
  });

  tearDownAll(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('cancelPayPalSubscription posts expected payload', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    late String capturedPath;
    Map<String, dynamic>? capturedBody;

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedPath = options.path;
          capturedBody = Map<String, dynamic>.from(options.data as Map);
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'subscriptionId': 'I-BW452GLLEP1G',
                'canceled': true,
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
    final storeService = await StoreService.initialize(apiService);

    final response = await storeService.cancelPayPalSubscription(
      playerId: 'player-123',
      subscriptionId: 'I-BW452GLLEP1G',
      reason: 'Canceled by customer',
    );

    expect(capturedPath, '/store/subscription/paypal/cancel');
    expect(
      capturedBody,
      {
        'playerId': 'player-123',
        'subscriptionId': 'I-BW452GLLEP1G',
        'reason': 'Canceled by customer',
      },
    );
    expect(response['canceled'], isTrue);
  });

  test('validateIap posts expected payload', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    late String capturedPath;
    Map<String, dynamic>? capturedBody;

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedPath = options.path;
          capturedBody = Map<String, dynamic>.from(options.data as Map);
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'validated': true,
                'provider': 'google_play',
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
    final storeService = await StoreService.initialize(apiService);

    final response = await storeService.validateIap(
      playerId: 'player-123',
      provider: 'google_play',
      productId: 'coins_500',
      purchaseToken: 'purchase-token-123',
      transactionId: 'order-123',
      metadata: {'platform': 'android'},
    );

    expect(capturedPath, '/store/iap/validate');
    expect(
      capturedBody,
      {
        'playerId': 'player-123',
        'provider': 'google_play',
        'productId': 'coins_500',
        'purchaseToken': 'purchase-token-123',
        'transactionId': 'order-123',
        'metadata': {'platform': 'android'},
      },
    );
    expect(response['validated'], isTrue);
  });

  test('getPlayerRewards loads reward center payload', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    late String capturedPath;

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedPath = options.path;
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'cards': [
                  {
                    'id': 'daily-checkin',
                    'title': 'Daily Check-in',
                    'subtitle': 'Day 3 of 7',
                    'gradient': ['#10B981', '#059669'],
                    'reward': '500 Coins',
                    'progress': 0.43,
                    'isAvailable': true,
                  },
                ],
                'completedCount': 1,
                'totalCount': 2,
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
    final storeService = await StoreService.initialize(apiService);

    final response = await storeService.getPlayerRewards('player-123');

    expect(capturedPath, '/store/rewards/player-123');
    expect(response.cards, hasLength(1));
    expect(response.cards.first.subtitle, 'Day 3 of 7');
    expect(response.completedCount, 1);
    expect(response.totalCount, 2);
  });

  test('claimPlayerReward posts expected path and empty payload', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    late String capturedPath;
    Map<String, dynamic>? capturedBody;

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedPath = options.path;
          capturedBody = Map<String, dynamic>.from(options.data as Map);
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'success': true,
                'rewardId': 'daily-checkin',
                'coinsAwarded': 500,
                'newBalance': 1940,
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
    final storeService = await StoreService.initialize(apiService);

    final response = await storeService.claimPlayerReward(
      playerId: 'player-123',
      rewardId: 'daily-checkin',
    );

    expect(capturedPath, '/store/rewards/player-123/claim/daily-checkin');
    expect(capturedBody, isEmpty);
    expect(response['success'], isTrue);
    expect(response['newBalance'], 1940);
  });
}
