import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:trivia_tycoon/core/dto/economy_dto.dart';
import 'package:trivia_tycoon/core/networking/http_client.dart';
import 'package:trivia_tycoon/core/networking/synaptix_api_client.dart';
import 'package:trivia_tycoon/core/services/api_service.dart';
import 'package:trivia_tycoon/core/services/auth_api_client.dart';
import 'package:trivia_tycoon/core/services/auth_http_client.dart';
import 'package:trivia_tycoon/core/services/auth_service.dart';
import 'package:trivia_tycoon/core/services/auth_token_store.dart';
import 'package:trivia_tycoon/core/services/device_id_service.dart';
import 'package:trivia_tycoon/core/services/event_queue_service.dart';
import 'package:trivia_tycoon/core/services/settings/general_key_value_storage_service.dart';
import 'package:trivia_tycoon/core/services/storage/secure_storage.dart';
import 'package:trivia_tycoon/game/analytics/services/analytics_service.dart';
import 'package:trivia_tycoon/game/controllers/economy_notifier.dart';
import 'package:trivia_tycoon/game/controllers/energy_notifier.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Fakes / Stubs
// ─────────────────────────────────────────────────────────────────────────────

class _FakeDeviceIdService extends DeviceIdService {
  _FakeDeviceIdService() : super(SecureStorage());

  @override
  Future<String> getOrCreate() async => 'test-device-id';

  @override
  String getDeviceType() => 'test';

  @override
  Future<Map<String, String>> getDeviceIdentityPayload() async =>
      {'deviceId': 'test-device-id', 'deviceType': 'test'};
}

class _StubHttpClient extends http.BaseClient {
  final http.Response Function(http.Request) handler;
  _StubHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final resp = handler(request as http.Request);
    return http.StreamedResponse(
      Stream.value(resp.bodyBytes),
      resp.statusCode,
      headers: resp.headers,
    );
  }
}

class _FakeStorage extends GeneralKeyValueStorageService {
  final Map<String, dynamic> _store = {};

  @override
  Future<dynamic> get(String key) async => _store[key];

  @override
  Future<int> getInt(String key) async {
    final v = _store[key];
    return v is int ? v : 0;
  }

  @override
  Future<void> setInt(String key, int value) async => _store[key] = value;

  @override
  Future<String?> getString(String key) async {
    final v = _store[key];
    return v is String ? v : null;
  }

  @override
  Future<void> setString(String key, String value) async => _store[key] = value;

  @override
  Future<bool?> getBool(String key) async {
    final v = _store[key];
    return v is bool ? v : null;
  }

  @override
  Future<void> setBool(String key, bool value) async => _store[key] = value;
}

class _FakeAnalyticsService extends AnalyticsService {
  final List<String> eventNames = [];
  final List<Map<String, dynamic>> eventData = [];

  _FakeAnalyticsService()
      : super(ApiService(baseUrl: 'http://noop', initializeCache: false),
            EventQueueService());

  @override
  Future<void> initialize(
      {String? initialSessionId, bool silent = true}) async {}

  @override
  Future<void> logEvent(String name, Map<String, dynamic> data) async {
    eventNames.add(name);
    eventData.add(data);
  }
}

/// Programmable fake that overrides every economy method on [SynaptixApiClient].
/// The underlying [HttpClient] is never invoked since all methods are overridden.
class _FakeApiClient extends SynaptixApiClient {
  int getEconomyStateCalls = 0;
  int sessionStartCalls = 0;
  int claimTicketCalls = 0;
  int reportLossCalls = 0;
  int reportWinCalls = 0;
  int startPolicyMatchCalls = 0;

  final List<dynamic> _economyResponses = [];
  final List<dynamic> _sessionResponses = [];
  final List<dynamic> _claimTicketResponses = [];
  final List<dynamic> _reportLossResponses = [];
  final List<dynamic> _reportWinResponses = [];
  final List<dynamic> _matchResponses = [];

  _FakeApiClient(HttpClient httpClient) : super(httpClient: httpClient);

  dynamic _next(List<dynamic> list, int idx) {
    if (list.isEmpty) throw StateError('No response configured for call $idx');
    return list[idx < list.length ? idx : list.length - 1];
  }

  void addEconomyState(dynamic r) => _economyResponses.add(r);
  void addSessionStart(dynamic r) => _sessionResponses.add(r);
  void addClaimTicket(dynamic r) => _claimTicketResponses.add(r);
  void addReportLoss(dynamic r) => _reportLossResponses.add(r);
  void addReportWin(dynamic r) => _reportWinResponses.add(r);
  void addMatch(dynamic r) => _matchResponses.add(r);

  @override
  Future<EconomyStateDto> getEconomyState({required String playerId}) async {
    final r = _next(_economyResponses, getEconomyStateCalls++);
    if (r is Exception) throw r;
    return r as EconomyStateDto;
  }

  @override
  Future<SessionStartDto> startEconomySession(
      {required String playerId}) async {
    final r = _next(_sessionResponses, sessionStartCalls++);
    if (r is Exception) throw r;
    return r as SessionStartDto;
  }

  @override
  Future<DailyTicketClaimDto> claimDailyJackpotTicket(
      {required String playerId}) async {
    final r = _next(_claimTicketResponses, claimTicketCalls++);
    if (r is Exception) throw r;
    return r as DailyTicketClaimDto;
  }

  @override
  Future<PityResponseDto> reportPityLoss({required String playerId}) async {
    final r = _next(_reportLossResponses, reportLossCalls++);
    if (r is Exception) throw r;
    return r as PityResponseDto;
  }

  @override
  Future<PityResponseDto> reportPityWin({required String playerId}) async {
    final r = _next(_reportWinResponses, reportWinCalls++);
    if (r is Exception) throw r;
    return r as PityResponseDto;
  }

  @override
  Future<MatchStartResultDto> startPolicyMatch({
    required String playerId,
    required String mode,
    Map<String, dynamic>? settings,
  }) async {
    final r = _next(_matchResponses, startPolicyMatchCalls++);
    if (r is Exception) throw r;
    return r as MatchStartResultDto;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

http.Response _jsonResp(Map<String, dynamic> body, {int status = 200}) =>
    http.Response(jsonEncode(body), status,
        headers: {'content-type': 'application/json'});

EconomyStateDto _stateDto({
  int energy = 40,
  int maxEnergy = 50,
  int regenIntervalMinutes = 30,
  bool firstSessionDiscount = false,
  bool dailyTicketAvailable = false,
  int dailyTicketsRemaining = 0,
  bool pityActive = false,
  Map<String, ModeCostDto> modes = const {},
}) =>
    EconomyStateDto(
      energy: energy,
      maxEnergy: maxEnergy,
      regenIntervalMinutes: regenIntervalMinutes,
      firstSessionDiscount: firstSessionDiscount,
      dailyTicketAvailable: dailyTicketAvailable,
      dailyTicketsRemaining: dailyTicketsRemaining,
      pityActive: pityActive,
      modes: modes,
    );

/// Builds a [SynaptixApiClient] backed by a real HTTP stub — used to test the
/// full HTTP → DTO parsing pipeline (e.g. 409 mapping).
SynaptixApiClient _buildRealClient(_StubHttpClient stub, Box authBox) {
  final store = AuthTokenStore(authBox);
  final deviceId = _FakeDeviceIdService();
  final authApi =
      AuthApiClient(stub, apiBaseUrl: 'https://test', deviceId: deviceId);
  final auth =
      BackendAuthService(deviceId: deviceId, tokenStore: store, api: authApi);
  final authHttp =
      AuthHttpClient(auth, store, innerClient: stub, autoRefresh: false);
  final httpClient = HttpClient(authClient: authHttp, baseUrl: 'https://test');
  return SynaptixApiClient(httpClient: httpClient);
}

/// Builds a [_FakeApiClient] whose HTTP layer is never invoked (all economy
/// methods are overridden).
_FakeApiClient _buildFakeClient(Box authBox) {
  final store = AuthTokenStore(authBox);
  final deviceId = _FakeDeviceIdService();
  final noop = _StubHttpClient((_) =>
      http.Response('{}', 200, headers: {'content-type': 'application/json'}));
  final authApi =
      AuthApiClient(noop, apiBaseUrl: 'https://test', deviceId: deviceId);
  final auth =
      BackendAuthService(deviceId: deviceId, tokenStore: store, api: authApi);
  final authHttp =
      AuthHttpClient(auth, store, innerClient: noop, autoRefresh: false);
  final httpClient = HttpClient(authClient: authHttp, baseUrl: 'https://test');
  return _FakeApiClient(httpClient);
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  late Directory tempDir;
  late Box authBox;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('economy_notifier_test');
    Hive.init(tempDir.path);
    authBox = await Hive.openBox('auth_tokens');
  });

  tearDown(() async {
    await authBox.close();
    await Hive.deleteBoxFromDisk('auth_tokens');
    await tempDir.delete(recursive: true);
  });

  // ── DTO parsing ─────────────────────────────────────────────────────────────

  group('ModeCostDto parsing', () {
    test('parses full payload', () {
      final dto = ModeCostDto.fromJson({
        'mode': 'ranked',
        'costType': 'energy',
        'baseCost': 4,
        'adjustedCost': 2,
        'available': true,
      });
      expect(dto.mode, 'ranked');
      expect(dto.costType, 'energy');
      expect(dto.baseCost, 4);
      expect(dto.adjustedCost, 2);
      expect(dto.available, isTrue);
    });

    test('effectiveCost returns adjustedCost when present', () {
      final dto = ModeCostDto.fromJson({
        'mode': 'casual',
        'costType': 'energy',
        'baseCost': 3,
        'adjustedCost': 1,
        'available': true
      });
      expect(dto.effectiveCost, 1);
    });

    test('effectiveCost falls back to baseCost when adjustedCost absent', () {
      final dto = ModeCostDto.fromJson({
        'mode': 'casual',
        'costType': 'energy',
        'baseCost': 3,
        'available': true
      });
      expect(dto.effectiveCost, 3);
    });

    test('hasDiscount true when adjustedCost < baseCost', () {
      final dto = ModeCostDto.fromJson({
        'mode': 'casual',
        'costType': 'energy',
        'baseCost': 4,
        'adjustedCost': 2,
        'available': true
      });
      expect(dto.hasDiscount, isTrue);
    });

    test('hasDiscount false when adjustedCost absent', () {
      final dto = ModeCostDto.fromJson({
        'mode': 'casual',
        'costType': 'energy',
        'baseCost': 4,
        'available': true
      });
      expect(dto.hasDiscount, isFalse);
    });

    test('defaults available to true on missing field', () {
      final dto = ModeCostDto.fromJson(
          {'mode': 'casual', 'costType': 'energy', 'baseCost': 3});
      expect(dto.available, isTrue);
    });
  });

  group('EconomyStateDto parsing', () {
    final fullJson = {
      'energy': 35,
      'maxEnergy': 50,
      'regenIntervalMinutes': 15,
      'firstSessionDiscount': true,
      'dailyTicketAvailable': true,
      'dailyTicketsRemaining': 2,
      'pityActive': true,
      'modes': {
        'casual': {
          'mode': 'casual',
          'costType': 'energy',
          'baseCost': 3,
          'available': true,
        },
        'jackpot': {
          'mode': 'jackpot',
          'costType': 'ticket',
          'baseCost': 1,
          'available': false,
        },
      },
    };

    test('parses full payload correctly', () {
      final dto = EconomyStateDto.fromJson(fullJson);
      expect(dto.energy, 35);
      expect(dto.maxEnergy, 50);
      expect(dto.regenIntervalMinutes, 15);
      expect(dto.firstSessionDiscount, isTrue);
      expect(dto.dailyTicketAvailable, isTrue);
      expect(dto.dailyTicketsRemaining, 2);
      expect(dto.pityActive, isTrue);
      expect(dto.modes.length, 2);
      expect(dto.modes['casual']!.costType, 'energy');
      expect(dto.modes['jackpot']!.available, isFalse);
    });

    test('applies sensible defaults on empty JSON', () {
      final dto = EconomyStateDto.fromJson({});
      expect(dto.energy, 0);
      expect(dto.maxEnergy, 50);
      expect(dto.regenIntervalMinutes, 30);
      expect(dto.firstSessionDiscount, isFalse);
      expect(dto.dailyTicketAvailable, isFalse);
      expect(dto.dailyTicketsRemaining, 0);
      expect(dto.pityActive, isFalse);
      expect(dto.modes, isEmpty);
    });

    test('round-trips through toJson / fromJson', () {
      final original = EconomyStateDto.fromJson(fullJson);
      final roundTripped = EconomyStateDto.fromJson(original.toJson());
      expect(roundTripped.energy, original.energy);
      expect(roundTripped.maxEnergy, original.maxEnergy);
      expect(roundTripped.modes.length, original.modes.length);
      expect(roundTripped.modes['casual']!.baseCost,
          original.modes['casual']!.baseCost);
    });
  });

  group('ReviveQuoteDto parsing', () {
    test('hasDiscount true when finalCost < baseCost', () {
      final dto = ReviveQuoteDto.fromJson({
        'baseCost': 100,
        'finalCost': 70,
        'almostWinApplied': true,
        'costCurrency': 'coins',
      });
      expect(dto.hasDiscount, isTrue);
      expect(dto.almostWinApplied, isTrue);
      expect(dto.costCurrency, 'coins');
    });

    test('hasDiscount false when finalCost == baseCost', () {
      final dto = ReviveQuoteDto.fromJson({
        'baseCost': 100,
        'finalCost': 100,
        'almostWinApplied': false,
        'costCurrency': 'gems'
      });
      expect(dto.hasDiscount, isFalse);
    });

    test('defaults to 0 cost on missing fields', () {
      final dto = ReviveQuoteDto.fromJson({});
      expect(dto.baseCost, 0);
      expect(dto.finalCost, 0);
      expect(dto.almostWinApplied, isFalse);
    });
  });

  group('DailyTicketClaimDto parsing', () {
    test('parses success response', () {
      final dto = DailyTicketClaimDto.fromJson(
          {'success': true, 'ticketsRemaining': 3});
      expect(dto.success, isTrue);
      expect(dto.ticketsRemaining, 3);
      expect(dto.denyReason, isNull);
    });

    test('parses denied response with reason', () {
      final dto = DailyTicketClaimDto.fromJson({
        'success': false,
        'ticketsRemaining': 0,
        'denyReason': 'already_claimed',
      });
      expect(dto.success, isFalse);
      expect(dto.denyReason, 'already_claimed');
    });
  });

  group('PityResponseDto parsing', () {
    test('parses pity active', () {
      final dto =
          PityResponseDto.fromJson({'pityActive': true, 'lossCount': 4});
      expect(dto.pityActive, isTrue);
      expect(dto.lossCount, 4);
    });

    test('defaults on empty JSON', () {
      final dto = PityResponseDto.fromJson({});
      expect(dto.pityActive, isFalse);
      expect(dto.lossCount, 0);
    });
  });

  group('SessionStartDto parsing', () {
    test('parses discountApplied with adjusted costs', () {
      final dto = SessionStartDto.fromJson({
        'discountApplied': true,
        'adjustedCosts': {
          'casual': {
            'mode': 'casual',
            'costType': 'energy',
            'baseCost': 3,
            'adjustedCost': 1,
            'available': true,
          },
        },
      });
      expect(dto.discountApplied, isTrue);
      expect(dto.adjustedCosts['casual']!.adjustedCost, 1);
    });

    test('defaults on empty JSON', () {
      final dto = SessionStartDto.fromJson({});
      expect(dto.discountApplied, isFalse);
      expect(dto.adjustedCosts, isEmpty);
    });
  });

  // ── EconomyState computed properties ────────────────────────────────────────

  group('EconomyState computed properties', () {
    test('isOffline when error set and lastFetched present', () {
      final s = EconomyState(
        error: 'network error',
        lastFetched: DateTime.now(),
      );
      expect(s.isOffline, isTrue);
    });

    test('isOffline false when no error', () {
      final s = EconomyState(lastFetched: DateTime.now());
      expect(s.isOffline, isFalse);
    });

    test('isOffline false when no cache (first load failure)', () {
      const s = EconomyState(error: 'network error');
      expect(s.isOffline, isFalse);
    });

    test('isEmpty when modes empty and no lastFetched', () {
      expect(EconomyState.initial.isEmpty, isTrue);
    });

    test('isEmpty false after successful fetch', () {
      final s = EconomyState(
        modes: {
          'casual': ModeCostDto.fromJson({
            'mode': 'casual',
            'costType': 'energy',
            'baseCost': 3,
            'available': true
          })
        },
        lastFetched: DateTime.now(),
      );
      expect(s.isEmpty, isFalse);
    });
  });

  // ── SynaptixApiClient.startPolicyMatch (HTTP-layer integration) ───────────────

  group('SynaptixApiClient.startPolicyMatch', () {
    test('returns started=true with matchId on 200', () async {
      final stub = _StubHttpClient((_) => _jsonResp({'matchId': 'match-abc'}));
      final client = _buildRealClient(stub, authBox);

      final result =
          await client.startPolicyMatch(playerId: 'p1', mode: 'casual');
      expect(result.started, isTrue);
      expect(result.matchId, 'match-abc');
      expect(result.denyReason, isNull);
    });

    test('returns started=false with denyReason on 409', () async {
      final stub = _StubHttpClient(
          (_) => _jsonResp({'message': 'insufficient_energy'}, status: 409));
      final client = _buildRealClient(stub, authBox);

      final result =
          await client.startPolicyMatch(playerId: 'p1', mode: 'ranked');
      expect(result.started, isFalse);
      expect(result.denyReason, contains('insufficient_energy'));
    });

    test('rethrows HttpException on 500', () async {
      final stub = _StubHttpClient(
          (_) => _jsonResp({'message': 'internal error'}, status: 500));
      final client = _buildRealClient(stub, authBox);

      await expectLater(
        () => client.startPolicyMatch(playerId: 'p1', mode: 'casual'),
        throwsA(isA<HttpException>()),
      );
    });

    test('rethrows HttpException on 400', () async {
      final stub = _StubHttpClient(
          (_) => _jsonResp({'message': 'bad request'}, status: 400));
      final client = _buildRealClient(stub, authBox);

      await expectLater(
        () => client.startPolicyMatch(playerId: 'p1', mode: 'casual'),
        throwsA(isA<HttpException>()),
      );
    });
  });

  // ── EconomyNotifier ─────────────────────────────────────────────────────────

  group('EconomyNotifier.fetchState', () {
    late _FakeApiClient api;
    late _FakeStorage storage;
    late _FakeAnalyticsService analytics;
    late EnergyNotifier energy;
    late EconomyNotifier notifier;

    setUp(() {
      api = _buildFakeClient(authBox);
      storage = _FakeStorage();
      analytics = _FakeAnalyticsService();
      energy = EnergyNotifier(storage);
      notifier = EconomyNotifier(api, energy, analytics, storage);
    });

    tearDown(() {
      notifier.dispose();
      energy.dispose();
    });

    test('success: state reflects dto values', () async {
      api.addEconomyState(_stateDto(
        energy: 30,
        maxEnergy: 50,
        pityActive: true,
        dailyTicketAvailable: true,
        dailyTicketsRemaining: 1,
      ));

      await notifier.fetchState('p1', maxRetries: 0);

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, isNull);
      expect(notifier.state.pityActive, isTrue);
      expect(notifier.state.dailyTicketAvailable, isTrue);
      expect(notifier.state.dailyTicketsRemaining, 1);
      expect(notifier.state.lastFetched, isNotNull);
    });

    test('success: caches state JSON in storage', () async {
      api.addEconomyState(_stateDto(energy: 20));

      await notifier.fetchState('p1', maxRetries: 0);

      final cached = await storage.getString('economy_last_state_json');
      expect(cached, isNotNull);
      final decoded = jsonDecode(cached!) as Map<String, dynamic>;
      expect(decoded['energy'], 20);
    });

    test('success: fires economy_state_loaded analytics event', () async {
      api.addEconomyState(_stateDto());

      await notifier.fetchState('p1', maxRetries: 0);

      expect(analytics.eventNames, contains('economy_state_loaded'));
      final data = analytics
          .eventData[analytics.eventNames.indexOf('economy_state_loaded')];
      expect(data['playerId'], 'p1');
      expect(data['attempt'], 0);
    });

    test('transient error retries — call count == 2 with maxRetries=1',
        () async {
      api.addEconomyState(Exception('SocketException: connection refused'));
      api.addEconomyState(_stateDto(energy: 25));

      await notifier.fetchState('p1', maxRetries: 1);

      expect(api.getEconomyStateCalls, 2);
      expect(notifier.state.error, isNull); // second attempt succeeded
    }, timeout: const Timeout(Duration(seconds: 10)));

    test('non-transient error (4xx) does not retry — call count == 1',
        () async {
      api.addEconomyState(Exception(
          'HttpException: POST /mobile/economy/state failed with status 404: not found'));

      await notifier.fetchState('p1', maxRetries: 1);

      expect(api.getEconomyStateCalls, 1);
    });

    test('all retries exhausted → error set', () async {
      api.addEconomyState(Exception('SocketException: host unreachable'));

      await notifier.fetchState('p1', maxRetries: 0);

      expect(notifier.state.error, isNotNull);
      expect(notifier.state.isLoading, isFalse);
    });

    test('isOffline true when cache exists and fetch fails', () async {
      // Pre-populate cache to simulate a previous successful fetch.
      await storage.setString('economy_last_state_json',
          jsonEncode(_stateDto(energy: 10).toJson()));
      // Re-create notifier so _hydrateCachedState runs with the pre-seeded cache.
      notifier.dispose();
      notifier = EconomyNotifier(api, energy, analytics, storage);
      await Future.delayed(Duration.zero); // let _hydrateCachedState resolve

      api.addEconomyState(Exception('SocketException: host unreachable'));
      await notifier.fetchState('p1', maxRetries: 0);

      expect(notifier.state.isOffline, isTrue);
    });

    test('all retries exhausted → fires economy_state_load_failed analytics',
        () async {
      api.addEconomyState(Exception('SocketException: host unreachable'));

      await notifier.fetchState('p1', maxRetries: 0);

      expect(analytics.eventNames, contains('economy_state_load_failed'));
    });
  });

  group('EconomyNotifier.claimTicket', () {
    late _FakeApiClient api;
    late _FakeStorage storage;
    late _FakeAnalyticsService analytics;
    late EnergyNotifier energy;
    late EconomyNotifier notifier;

    setUp(() {
      api = _buildFakeClient(authBox);
      storage = _FakeStorage();
      analytics = _FakeAnalyticsService();
      energy = EnergyNotifier(storage);
      notifier = EconomyNotifier(api, energy, analytics, storage);
    });

    tearDown(() {
      notifier.dispose();
      energy.dispose();
    });

    test('success: updates ticket state', () async {
      api.addClaimTicket(
          const DailyTicketClaimDto(success: true, ticketsRemaining: 2));

      await notifier.claimTicket('p1');

      expect(notifier.state.dailyTicketAvailable, isTrue);
      expect(notifier.state.dailyTicketsRemaining, 2);
      expect(analytics.eventNames, contains('daily_ticket_claimed'));
    });

    test('success: dailyTicketAvailable false when ticketsRemaining == 0',
        () async {
      api.addClaimTicket(
          const DailyTicketClaimDto(success: true, ticketsRemaining: 0));

      await notifier.claimTicket('p1');

      expect(notifier.state.dailyTicketAvailable, isFalse);
    });

    test('denied: fires daily_ticket_denied with reason', () async {
      api.addClaimTicket(const DailyTicketClaimDto(
          success: false, ticketsRemaining: 0, denyReason: 'already_claimed'));

      await notifier.claimTicket('p1');

      expect(analytics.eventNames, contains('daily_ticket_denied'));
      final idx = analytics.eventNames.indexOf('daily_ticket_denied');
      expect(analytics.eventData[idx]['reason'], 'already_claimed');
    });
  });

  group('EconomyNotifier.reportLoss', () {
    late _FakeApiClient api;
    late _FakeStorage storage;
    late _FakeAnalyticsService analytics;
    late EnergyNotifier energy;
    late EconomyNotifier notifier;

    setUp(() {
      api = _buildFakeClient(authBox);
      storage = _FakeStorage();
      analytics = _FakeAnalyticsService();
      energy = EnergyNotifier(storage);
      notifier = EconomyNotifier(api, energy, analytics, storage);
    });

    tearDown(() {
      notifier.dispose();
      energy.dispose();
    });

    test('updates pityActive when server activates pity', () async {
      api.addReportLoss(const PityResponseDto(pityActive: true, lossCount: 3));

      await notifier.reportLoss('p1');

      expect(notifier.state.pityActive, isTrue);
      expect(analytics.eventNames, contains('pity_state_changed'));
    });

    test('clears pityActive when server resets pity', () async {
      api.addReportLoss(const PityResponseDto(pityActive: false, lossCount: 0));

      await notifier.reportLoss('p1');

      expect(notifier.state.pityActive, isFalse);
    });

    test('silently ignores network failure', () async {
      api.addReportLoss(Exception('SocketException: timeout'));

      // Should not throw
      await notifier.reportLoss('p1');

      expect(notifier.state.pityActive, isFalse); // unchanged
    });
  });

  group('EconomyNotifier.startSession', () {
    late _FakeApiClient api;
    late _FakeStorage storage;
    late _FakeAnalyticsService analytics;
    late EnergyNotifier energy;
    late EconomyNotifier notifier;

    setUp(() {
      api = _buildFakeClient(authBox);
      storage = _FakeStorage();
      analytics = _FakeAnalyticsService();
      energy = EnergyNotifier(storage);
      notifier = EconomyNotifier(api, energy, analytics, storage);
    });

    tearDown(() {
      notifier.dispose();
      energy.dispose();
    });

    test('merges adjustedCosts into modes', () async {
      // Seed an existing mode map.
      api.addEconomyState(_stateDto(modes: {
        'casual': ModeCostDto.fromJson({
          'mode': 'casual',
          'costType': 'energy',
          'baseCost': 3,
          'available': true
        }),
        'ranked': ModeCostDto.fromJson({
          'mode': 'ranked',
          'costType': 'energy',
          'baseCost': 4,
          'available': true
        }),
      }));
      await notifier.fetchState('p1', maxRetries: 0);

      // Session start returns a discount for 'casual' only.
      api.addSessionStart(SessionStartDto(
        discountApplied: true,
        adjustedCosts: {
          'casual': ModeCostDto.fromJson({
            'mode': 'casual',
            'costType': 'energy',
            'baseCost': 3,
            'adjustedCost': 1,
            'available': true,
          }),
        },
      ));

      await notifier.startSession('p1', 'casual');

      expect(notifier.state.modes.length, 2); // both modes still present
      expect(notifier.state.modes['casual']!.adjustedCost, 1);
      expect(notifier.state.modes['ranked']!.adjustedCost, isNull); // untouched
    });

    test('returns null on network failure', () async {
      api.addSessionStart(Exception('SocketException: timeout'));

      final result = await notifier.startSession('p1', 'casual');

      expect(result, isNull);
    });
  });

  group('EconomyNotifier.enterMode', () {
    late _FakeApiClient api;
    late _FakeStorage storage;
    late _FakeAnalyticsService analytics;
    late EnergyNotifier energy;
    late EconomyNotifier notifier;

    setUp(() {
      api = _buildFakeClient(authBox);
      storage = _FakeStorage();
      analytics = _FakeAnalyticsService();
      energy = EnergyNotifier(storage);
      notifier = EconomyNotifier(api, energy, analytics, storage);
    });

    tearDown(() {
      notifier.dispose();
      energy.dispose();
    });

    test('started=true fires mode_entry_attempted analytics', () async {
      api.addMatch(
          const MatchStartResultDto(started: true, matchId: 'match-1'));

      final result = await notifier.enterMode('p1', 'casual');

      expect(result.started, isTrue);
      expect(analytics.eventNames, contains('mode_entry_attempted'));
    });

    test('started=false fires mode_entry_blocked analytics with reasonCode',
        () async {
      api.addMatch(const MatchStartResultDto(
          started: false, denyReason: 'insufficient_energy'));

      final result = await notifier.enterMode('p1', 'casual');

      expect(result.started, isFalse);
      expect(analytics.eventNames, contains('mode_entry_blocked'));
      final idx = analytics.eventNames.indexOf('mode_entry_blocked');
      expect(analytics.eventData[idx]['reasonCode'], 'insufficient_energy');
    });
  });
}
