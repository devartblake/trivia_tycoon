import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'compliance_service.dart';
import 'compliance_status_model.dart';

// Must be overridden in a ProviderScope; defaults to null (compliance gates fail closed).
final complianceServiceProvider = Provider<ComplianceService?>((ref) => null);

// Per-user compliance status — drives UI gating for crypto and prize surfaces
final complianceStatusProvider = FutureProvider.family<ComplianceStatus, String>(
  (ref, userId) async {
    final service = ref.watch(complianceServiceProvider);
    if (service == null) return _blockedStatus(userId);
    return service.getStatus(userId);
  },
);

// Convenience booleans consumed by feature guards
final canUseCryptoProvider = FutureProvider.family<bool, String>(
  (ref, userId) async {
    final status = await ref.watch(complianceStatusProvider(userId).future);
    return status.canUseCrypto;
  },
);

final canReceivePrizesProvider = FutureProvider.family<bool, String>(
  (ref, userId) async {
    final status = await ref.watch(complianceStatusProvider(userId).future);
    return status.canReceivePrizes;
  },
);

ComplianceStatus _blockedStatus(String userId) => ComplianceStatus(
  userId:          userId,
  kycStatus:       KycStatus.notStarted,
  ageStatus:       AgeStatus.unknown,
  geoStatus:       GeoStatus.unchecked,
  amlStatus:       AmlStatus.clear,
  consentStatus:   ConsentStatus.notGiven,
  canUseCrypto:    false,
  canReceivePrizes: false,
  canCollectData:  false,
  requiredActions: [],
);
