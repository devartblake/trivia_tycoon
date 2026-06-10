// Mirrors ComplianceService/Data/Entities.cs enums exactly
enum KycStatus    { notStarted, pending, approved, rejected, expired }
enum AgeStatus    { unknown, coppaMinor, minor, adult }
enum GeoStatus    { unchecked, allowed, restricted, blocked }
enum AmlStatus    { clear, underReview, flagged, blocked }
enum ConsentStatus { notGiven, partial, full }

// ── Parse helpers (file-private) ─────────────────────────────────────────────

KycStatus _parseKycStatus(Object? v) => switch ('$v') {
  'NotStarted' || 'notStarted' || '0' => KycStatus.notStarted,
  'Pending'    || 'pending'    || '1' => KycStatus.pending,
  'Approved'   || 'approved'   || '2' => KycStatus.approved,
  'Rejected'   || 'rejected'   || '3' => KycStatus.rejected,
  'Expired'    || 'expired'    || '4' => KycStatus.expired,
  _ => KycStatus.notStarted,
};

AgeStatus _parseAgeStatus(Object? v) => switch ('$v') {
  'Unknown'    || 'unknown'    || '0' => AgeStatus.unknown,
  'CoppaMinor' || 'coppaMinor' || '1' => AgeStatus.coppaMinor,
  'Minor'      || 'minor'      || '2' => AgeStatus.minor,
  'Adult'      || 'adult'      || '3' => AgeStatus.adult,
  _ => AgeStatus.unknown,
};

GeoStatus _parseGeoStatus(Object? v) => switch ('$v') {
  'Unchecked'  || 'unchecked'  || '0' => GeoStatus.unchecked,
  'Allowed'    || 'allowed'    || '1' => GeoStatus.allowed,
  'Restricted' || 'restricted' || '2' => GeoStatus.restricted,
  'Blocked'    || 'blocked'    || '3' => GeoStatus.blocked,
  _ => GeoStatus.unchecked,
};

AmlStatus _parseAmlStatus(Object? v) => switch ('$v') {
  'Clear'       || 'clear'       || '0' => AmlStatus.clear,
  'UnderReview' || 'underReview' || '1' => AmlStatus.underReview,
  'Flagged'     || 'flagged'     || '2' => AmlStatus.flagged,
  'Blocked'     || 'blocked'     || '3' => AmlStatus.blocked,
  _ => AmlStatus.clear,
};

ConsentStatus _parseConsentStatus(Object? v) => switch ('$v') {
  'NotGiven' || 'notGiven' || '0' => ConsentStatus.notGiven,
  'Partial'  || 'partial'  || '1' => ConsentStatus.partial,
  'Full'     || 'full'     || '2' => ConsentStatus.full,
  _ => ConsentStatus.notGiven,
};

// ── Models ────────────────────────────────────────────────────────────────────

class ComplianceStatus {
  final String userId;
  final KycStatus     kycStatus;
  final AgeStatus     ageStatus;
  final GeoStatus     geoStatus;
  final AmlStatus     amlStatus;
  final ConsentStatus consentStatus;
  final String?       lastStateCode;
  final bool canUseCrypto;
  final bool canReceivePrizes;
  final bool canCollectData;
  final List<String>  requiredActions;
  final DateTime?     lastUpdated;

  const ComplianceStatus({
    required this.userId,
    required this.kycStatus,
    required this.ageStatus,
    required this.geoStatus,
    required this.amlStatus,
    required this.consentStatus,
    this.lastStateCode,
    required this.canUseCrypto,
    required this.canReceivePrizes,
    required this.canCollectData,
    required this.requiredActions,
    this.lastUpdated,
  });

  factory ComplianceStatus.fromJson(Map<String, dynamic> json) => ComplianceStatus(
    userId:          json['userId']        as String?  ?? '',
    kycStatus:       _parseKycStatus(json['kycStatus']),
    ageStatus:       _parseAgeStatus(json['ageStatus']),
    geoStatus:       _parseGeoStatus(json['geoStatus']),
    amlStatus:       _parseAmlStatus(json['amlStatus']),
    consentStatus:   _parseConsentStatus(json['consentStatus']),
    lastStateCode:   json['lastStateCode'] as String?,
    canUseCrypto:    json['canUseCrypto']     as bool? ?? false,
    canReceivePrizes: json['canReceivePrizes'] as bool? ?? false,
    canCollectData:  json['canCollectData']   as bool? ?? false,
    requiredActions: (json['requiredActions'] as List<dynamic>? ?? []).cast<String>(),
    lastUpdated:     json['lastUpdated'] != null
        ? DateTime.tryParse(json['lastUpdated'] as String)
        : null,
  );

  // Convenience gates used by UI and service guards
  bool get needsKyc            => kycStatus == KycStatus.notStarted || kycStatus == KycStatus.rejected || kycStatus == KycStatus.expired;
  bool get needsAgeVerification => ageStatus == AgeStatus.unknown;
  bool get needsConsent         => consentStatus == ConsentStatus.notGiven;
  bool get isGeoBlocked         => geoStatus == GeoStatus.restricted || geoStatus == GeoStatus.blocked;
  bool get isFullyCompliant     => canUseCrypto && canCollectData;
}

class KycInitiateResult {
  final String  userId;
  final String  stripeSessionId;
  final String? clientSecret;
  final String? verificationUrl;

  const KycInitiateResult({
    required this.userId,
    required this.stripeSessionId,
    this.clientSecret,
    this.verificationUrl,
  });

  factory KycInitiateResult.fromJson(Map<String, dynamic> json) => KycInitiateResult(
    userId:          json['userId']          as String? ?? '',
    stripeSessionId: json['stripeSessionId'] as String? ?? '',
    clientSecret:    json['clientSecret']    as String?,
    verificationUrl: json['verificationUrl'] as String?,
  );
}

class AgeVerificationResult {
  final String    userId;
  final AgeStatus ageStatus;
  final bool      isCoppaCompliant;
  final bool      isPrizeEligible;
  final int       minAgeRequired;

  const AgeVerificationResult({
    required this.userId,
    required this.ageStatus,
    required this.isCoppaCompliant,
    required this.isPrizeEligible,
    required this.minAgeRequired,
  });

  factory AgeVerificationResult.fromJson(Map<String, dynamic> json) => AgeVerificationResult(
    userId:           json['userId']           as String? ?? '',
    ageStatus:        _parseAgeStatus(json['ageStatus']),
    isCoppaCompliant: json['isCoppaCompliant'] as bool? ?? false,
    isPrizeEligible:  json['isPrizeEligible']  as bool? ?? false,
    minAgeRequired:   json['minAgeRequired']   as int?  ?? 18,
  );
}

class AmlCheckResult {
  final String    userId;
  final AmlStatus amlStatus;
  final bool      isAllowed;
  final bool      requiresReview;
  final String?   alertReason;
  final double    dailyTotal;

  const AmlCheckResult({
    required this.userId,
    required this.amlStatus,
    required this.isAllowed,
    required this.requiresReview,
    this.alertReason,
    required this.dailyTotal,
  });

  factory AmlCheckResult.fromJson(Map<String, dynamic> json) => AmlCheckResult(
    userId:         json['userId']         as String? ?? '',
    amlStatus:      _parseAmlStatus(json['amlStatus']),
    isAllowed:      json['isAllowed']      as bool?   ?? false,
    requiresReview: json['requiresReview'] as bool?   ?? false,
    alertReason:    json['alertReason']    as String?,
    dailyTotal:     (json['dailyTotal']    as num?    ?? 0).toDouble(),
  );
}

class GeoCheckResult {
  final String    userId;
  final String    stateCode;
  final GeoStatus geoStatus;
  final bool      isAllowed;
  final String?   restrictionReason;

  const GeoCheckResult({
    required this.userId,
    required this.stateCode,
    required this.geoStatus,
    required this.isAllowed,
    this.restrictionReason,
  });

  factory GeoCheckResult.fromJson(Map<String, dynamic> json) => GeoCheckResult(
    userId:            json['userId']            as String? ?? '',
    stateCode:         json['stateCode']         as String? ?? '',
    geoStatus:         _parseGeoStatus(json['geoStatus']),
    isAllowed:         json['isAllowed']         as bool?   ?? false,
    restrictionReason: json['restrictionReason'] as String?,
  );
}

class DataSubjectRequestResult {
  final String   requestId;
  final String   userId;
  final String   requestType;
  final String   status;
  final String   message;
  final DateTime createdAt;

  const DataSubjectRequestResult({
    required this.requestId,
    required this.userId,
    required this.requestType,
    required this.status,
    required this.message,
    required this.createdAt,
  });

  factory DataSubjectRequestResult.fromJson(Map<String, dynamic> json) => DataSubjectRequestResult(
    requestId:   json['requestId']   as String? ?? '',
    userId:      json['userId']      as String? ?? '',
    requestType: json['requestType'] as String? ?? '',
    status:      json['status']      as String? ?? '',
    message:     json['message']     as String? ?? '',
    createdAt:   DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
  );
}
