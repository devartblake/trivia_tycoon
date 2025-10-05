import 'package:equatable/equatable.dart';

enum ReferralCodeStatus { active, disabled, expired }

class ReferralCode extends Equatable {
  final String code;            // e.g., "RC8A9K2M"
  final String ownerUserId;     // inviter userId
  final DateTime createdAt;
  final DateTime? expiresAt;    // null => no expiry
  final ReferralCodeStatus status;
  final bool isSynced;          // local vs server state
  final String? serverId;       // server PK if known

  const ReferralCode({
    required this.code,
    required this.ownerUserId,
    required this.createdAt,
    this.expiresAt,
    this.status = ReferralCodeStatus.active,
    this.isSynced = false,
    this.serverId,
  });

  ReferralCode copyWith({
    String? code,
    String? ownerUserId,
    DateTime? createdAt,
    DateTime? expiresAt,
    ReferralCodeStatus? status,
    bool? isSynced,
    String? serverId,
  }) {
    return ReferralCode(
      code: code ?? this.code,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      isSynced: isSynced ?? this.isSynced,
      serverId: serverId ?? this.serverId,
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'ownerUserId': ownerUserId,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'expiresAt': expiresAt?.toUtc().toIso8601String(),
    'status': status.name,
    'isSynced': isSynced,
    'serverId': serverId,
  };

  factory ReferralCode.fromJson(Map<String, dynamic> json) => ReferralCode(
    code: json['code'] as String,
    ownerUserId: json['ownerUserId'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
    expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt'] as String).toUtc() : null,
    status: ReferralCodeStatus.values.firstWhere(
          (e) => e.name == (json['status'] as String? ?? 'active'),
      orElse: () => ReferralCodeStatus.active,
    ),
    isSynced: (json['isSynced'] as bool?) ?? false,
    serverId: json['serverId'] as String?,
  );

  @override
  List<Object?> get props => [code, ownerUserId, createdAt, expiresAt, status, isSynced, serverId];
}

class ReferralScanEvent extends Equatable {
  final String code;
  final String? scannerUserId; // who scanned (may be null if not signed in)
  final DateTime scannedAt;
  final String source;         // "qr" | "link" | "manual"
  final String? campaignId;    // optional attribution tag

  const ReferralScanEvent({
    required this.code,
    this.scannerUserId,
    required this.scannedAt,
    this.source = 'qr',
    this.campaignId,
  });

  Map<String, dynamic> toJson() => {
    'code': code,
    'scannerUserId': scannerUserId,
    'scannedAt': scannedAt.toUtc().toIso8601String(),
    'source': source,
    'campaignId': campaignId,
  };

  factory ReferralScanEvent.fromJson(Map<String, dynamic> json) => ReferralScanEvent(
    code: json['code'] as String,
    scannerUserId: json['scannerUserId'] as String?,
    scannedAt: DateTime.parse(json['scannedAt'] as String).toUtc(),
    source: (json['source'] as String?) ?? 'qr',
    campaignId: json['campaignId'] as String?,
  );

  @override
  List<Object?> get props => [code, scannerUserId, scannedAt, source, campaignId];
}
