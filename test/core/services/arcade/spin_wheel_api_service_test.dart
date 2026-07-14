import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/core/services/api_service.dart';
import 'package:synaptix/core/services/arcade/spin_wheel_api_service.dart';

void main() {
  group('SpinWheelApiService', () {
    test('fetchSegments parses backend segment list', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      late String capturedPath;
      Map<String, dynamic>? capturedQuery;

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedPath = options.path;
            capturedQuery = Map<String, dynamic>.from(options.queryParameters);
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: [
                  {
                    'id': 'coins-100',
                    'label': '100 Coins',
                    'rewardType': 'coins',
                    'reward': 100,
                    'color': '#F59E0B',
                  },
                ],
              ),
            );
          },
        ),
      );

      final api = ApiService(
        baseUrl: 'https://example.test',
        dio: dio,
        initializeCache: false,
      );
      final service = SpinWheelApiService(api);

      final segments = await service.fetchSegments(playerId: 'player-123');

      expect(capturedPath, '/arcade/spin/segments');
      expect(capturedQuery, {'playerId': 'player-123'});
      expect(segments, hasLength(1));
      expect(segments.first.id, 'coins-100');
      expect(segments.first.reward, 100);
    });

    test('claimReward posts expected body and parses new balance', () async {
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
                  'coinsGranted': 100,
                  'newBalance': 1940,
                  'message': 'Reward claimed',
                },
              ),
            );
          },
        ),
      );

      final api = ApiService(
        baseUrl: 'https://example.test',
        dio: dio,
        initializeCache: false,
      );
      final service = SpinWheelApiService(api);

      final response = await service.claimReward(
        playerId: 'player-123',
        segmentId: 'coins-100',
        spinId: 'spin-abc',
      );

      expect(capturedPath, '/arcade/spin/claim');
      expect(capturedBody, {
        'playerId': 'player-123',
        'segmentId': 'coins-100',
        'spinId': 'spin-abc',
      });
      expect(response.success, isTrue);
      expect(response.coinsGranted, 100);
      expect(response.newBalance, 1940);
    });

    test('claimStartedReward posts token-based body without segmentId',
        () async {
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
                  'coinsGranted': 75,
                  'newBalance': 2015,
                  'message': 'Reward claimed',
                },
              ),
            );
          },
        ),
      );

      final api = ApiService(
        baseUrl: 'https://example.test',
        dio: dio,
        initializeCache: false,
      );
      final service = SpinWheelApiService(api);

      final response = await service.claimStartedReward(
        spinId: 'spin-abc',
        claimToken: 'claim-token',
        idempotencyKey: 'spin-abc-claim-token',
      );

      expect(capturedPath, '/arcade/spin/claim');
      expect(capturedBody, {
        'spinId': 'spin-abc',
        'claimToken': 'claim-token',
        'idempotencyKey': 'spin-abc-claim-token',
      });
      expect(capturedBody, isNot(contains('segmentId')));
      expect(response.success, isTrue);
      expect(response.coinsGranted, 75);
      expect(response.newBalance, 2015);
    });
  });
}
