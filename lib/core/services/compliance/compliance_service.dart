import 'compliance_api_client.dart';
import 'compliance_status_model.dart';

class ComplianceService {
  final ComplianceApiClient _client;

  // Short-lived cache so UI doesn't fire a network call on every rebuild.
  // Invalidated immediately after any mutation (age verify, KYC initiate, etc.)
  ComplianceStatus? _cached;
  DateTime? _cacheExpiry;
  static const _cacheTtl = Duration(minutes: 5);

  ComplianceService(this._client);

  // ── Status ────────────────────────────────────────────────────────────────

  Future<ComplianceStatus> getStatus(
    String userId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _cached?.userId == userId &&
        _cacheExpiry != null &&
        DateTime.now().isBefore(_cacheExpiry!)) {
      return _cached!;
    }

    try {
      final status = await _client.getStatus(userId);
      _cached      = status;
      _cacheExpiry = DateTime.now().add(_cacheTtl);
      return status;
    } catch (_) {
      // Fail closed: treat as fully non-compliant when the service is unreachable
      return _cached?.userId == userId
          ? _cached!
          : _unknownStatus(userId);
    }
  }

  void invalidateCache() {
    _cached      = null;
    _cacheExpiry = null;
  }

  // ── Permission gates (used by crypto + prize guards) ──────────────────────

  Future<bool> canUseCrypto(String userId) async =>
      (await getStatus(userId)).canUseCrypto;

  Future<bool> canReceivePrizes(String userId) async =>
      (await getStatus(userId)).canReceivePrizes;

  // ── KYC ───────────────────────────────────────────────────────────────────

  Future<KycInitiateResult> initiateKyc(String userId, String returnUrl) async {
    final result = await _client.initiateKyc(userId, returnUrl);
    invalidateCache();
    return result;
  }

  // ── Age verification ──────────────────────────────────────────────────────

  Future<AgeVerificationResult> verifyAge(String userId, DateTime dateOfBirth) async {
    final result = await _client.verifyAge(userId, dateOfBirth);
    invalidateCache();
    return result;
  }

  // ── Geo ───────────────────────────────────────────────────────────────────

  Future<GeoCheckResult> checkGeo(String userId, String stateCode) async {
    final result = await _client.checkGeo(userId, stateCode);
    invalidateCache();
    return result;
  }

  // ── AML ───────────────────────────────────────────────────────────────────

  Future<AmlCheckResult> checkTransaction(
    String userId,
    double amount,
    String network,
    String transactionType,
  ) => _client.checkTransaction(userId, amount, network, transactionType);

  // ── CCPA ──────────────────────────────────────────────────────────────────

  Future<DataSubjectRequestResult> requestDataExport(String userId) =>
      _client.requestDataExport(userId);

  Future<DataSubjectRequestResult> requestDataDeletion(String userId) =>
      _client.requestDataDeletion(userId);

  Future<void> recordConsent(String userId, String consentType, {required bool granted}) =>
      _client.recordConsent(userId, consentType, granted: granted);

  // ── Helpers ───────────────────────────────────────────────────────────────

  static ComplianceStatus _unknownStatus(String userId) => ComplianceStatus(
    userId:          userId,
    kycStatus:       KycStatus.notStarted,
    ageStatus:       AgeStatus.unknown,
    geoStatus:       GeoStatus.unchecked,
    amlStatus:       AmlStatus.clear,
    consentStatus:   ConsentStatus.notGiven,
    canUseCrypto:    false,
    canReceivePrizes: false,
    canCollectData:  false,
    requiredActions: ['kyc', 'age_verification', 'consent', 'geo_check'],
  );
}
