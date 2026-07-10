import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:trivia_tycoon/core/services/compliance/compliance_api_client.dart';
import 'package:trivia_tycoon/core/services/compliance/compliance_service.dart';
import 'package:trivia_tycoon/core/services/compliance/compliance_status_model.dart';

void main() {
  group('ComplianceService.getStatus', () {
    test('caches status within TTL for repeated calls', () async {
      final client = _FakeComplianceApiClient()
        ..enqueueStatus((userId) => _status(userId, canUseCrypto: true));
      final service = ComplianceService(client);

      final first = await service.getStatus('user-1');
      final second = await service.getStatus('user-1');

      expect(second, same(first));
      expect(client.getStatusCallCount, 1);
    });

    test('returns cached status when refresh fails and cache is still valid',
        () async {
      final client = _FakeComplianceApiClient()
        ..enqueueStatus((userId) => _status(userId, canUseCrypto: true))
        ..enqueueStatusError(const ComplianceApiException(
          message: 'network failure',
          path: '/api/compliance/status/user-1',
        ));
      final service = ComplianceService(client);

      final cached = await service.getStatus('user-1');
      final fallback = await service.getStatus('user-1', forceRefresh: true);

      expect(fallback, same(cached));
      expect(client.getStatusCallCount, 2);
    });

    test('returns unknown status when request fails without a reusable cache',
        () async {
      final client = _FakeComplianceApiClient()
        ..enqueueStatusError(const ComplianceApiException(
          message: 'network failure',
          path: '/api/compliance/status/user-1',
        ));
      final service = ComplianceService(client);

      final status = await service.getStatus('user-1');

      expect(status.userId, 'user-1');
      expect(status.canUseCrypto, isFalse);
      expect(status.canReceivePrizes, isFalse);
      expect(status.canCollectData, isFalse);
      expect(
        status.requiredActions,
        containsAll(
            <String>['kyc', 'age_verification', 'consent', 'geo_check']),
      );
      expect(client.getStatusCallCount, 1);
    });
  });
}

class _FakeComplianceApiClient extends ComplianceApiClient {
  _FakeComplianceApiClient()
      : super(http.Client(), baseUrl: 'https://example.test');

  final List<Future<ComplianceStatus> Function(String userId)> _statusCalls =
      [];
  int getStatusCallCount = 0;

  void enqueueStatus(ComplianceStatus Function(String userId) handler) {
    _statusCalls.add((userId) async => handler(userId));
  }

  void enqueueStatusError(Object error) {
    _statusCalls.add((_) async => throw error);
  }

  @override
  Future<ComplianceStatus> getStatus(String userId) async {
    getStatusCallCount++;
    if (_statusCalls.isEmpty) {
      throw StateError('No queued status response');
    }
    final call = _statusCalls.removeAt(0);
    return call(userId);
  }
}

ComplianceStatus _status(String userId, {required bool canUseCrypto}) =>
    ComplianceStatus(
      userId: userId,
      kycStatus: KycStatus.approved,
      ageStatus: AgeStatus.adult,
      geoStatus: GeoStatus.allowed,
      amlStatus: AmlStatus.clear,
      consentStatus: ConsentStatus.full,
      canUseCrypto: canUseCrypto,
      canReceivePrizes: canUseCrypto,
      canCollectData: true,
      requiredActions: const [],
    );
