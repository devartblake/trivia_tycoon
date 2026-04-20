import 'package:equatable/equatable.dart';

enum ReferralCodeStatus { active, disabled, expired }

enum InviteStatus { pending, redeemed, expired }

class ReferralCode extends Equatable {
  final String code; // e.g., "RC8A9K2M"
  final String ownerUserId; // inviter userId
  final DateTime createdAt;
  final DateTime? expiresAt; // null => no expiry
  final ReferralCodeStatus status;
  final bool isSynced; // local vs server state
  final String? serverId; // server PK if known

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
        expiresAt: json['expiresAt'] != null
            ? DateTime.parse(json['expiresAt'] as String).toUtc()
            : null,
        status: ReferralCodeStatus.values.firstWhere(
          (e) => e.name == (json['status'] as String? ?? 'active'),
          orElse: () => ReferralCodeStatus.active,
        ),
        isSynced: (json['isSynced'] as bool?) ?? false,
        serverId: json['serverId'] as String?,
      );

  @override
  List<Object?> get props =>
      [code, ownerUserId, createdAt, expiresAt, status, isSynced, serverId];
}

class ReferralInvite extends Equatable {
  final String id; // unique invite ID (UUID)
  final String referrerUserId; // who created the invite
  final String referralCode; // the referral code being used
  final DateTime createdAt;
  final DateTime expiresAt; // auto-calculated: createdAt + 7 days
  final InviteStatus status; // pending, redeemed, or expired
  final String? redeemedBy; // userId who redeemed
  final DateTime? redeemedAt; // when redeemed
  final String? inviteeName; // optional: name of person invited
  final String? inviteeEmail; // optional: email of person invited
  final bool isSynced; // synced to server?
  final String? serverId; // server-side ID if synced
  final Map<String, dynamic>? metadata; // additional data

  const ReferralInvite({
    required this.id,
    required this.referrerUserId,
    required this.referralCode,
    required this.createdAt,
    required this.expiresAt,
    this.status = InviteStatus.pending,
    this.redeemedBy,
    this.redeemedAt,
    this.inviteeName,
    this.inviteeEmail,
    this.isSynced = false,
    this.serverId,
    this.metadata,
  });

  /// Check if invite is expired
  bool get isExpired {
    if (status == InviteStatus.expired) return true;
    return DateTime.now().isAfter(expiresAt);
  }

  /// Check if invite is redeemed
  bool get isRedeemed => status == InviteStatus.redeemed;

  /// Check if invite is still pending and valid
  bool get isPending => status == InviteStatus.pending && !isExpired;

  /// Get remaining days until expiration
  int get daysUntilExpiration {
    if (isExpired || isRedeemed) return 0;
    final difference = expiresAt.difference(DateTime.now());
    return difference.inDays;
  }

  /// Get remaining hours until expiration
  int get hoursUntilExpiration {
    if (isExpired || isRedeemed) return 0;
    final difference = expiresAt.difference(DateTime.now());
    return difference.inHours;
  }

  ReferralInvite copyWith({
    String? id,
    String? referrerUserId,
    String? referralCode,
    DateTime? createdAt,
    DateTime? expiresAt,
    InviteStatus? status,
    String? redeemedBy,
    DateTime? redeemedAt,
    String? inviteeName,
    String? inviteeEmail,
    bool? isSynced,
    String? serverId,
    Map<String, dynamic>? metadata,
  }) {
    return ReferralInvite(
      id: id ?? this.id,
      referrerUserId: referrerUserId ?? this.referrerUserId,
      referralCode: referralCode ?? this.referralCode,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      redeemedBy: redeemedBy ?? this.redeemedBy,
      redeemedAt: redeemedAt ?? this.redeemedAt,
      inviteeName: inviteeName ?? this.inviteeName,
      inviteeEmail: inviteeEmail ?? this.inviteeEmail,
      isSynced: isSynced ?? this.isSynced,
      serverId: serverId ?? this.serverId,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'referrerUserId': referrerUserId,
        'referralCode': referralCode,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'expiresAt': expiresAt.toUtc().toIso8601String(),
        'status': status.name,
        'redeemedBy': redeemedBy,
        'redeemedAt': redeemedAt?.toUtc().toIso8601String(),
        'inviteeName': inviteeName,
        'inviteeEmail': inviteeEmail,
        'isSynced': isSynced,
        'serverId': serverId,
        'metadata': metadata,
      };

  factory ReferralInvite.fromJson(Map<String, dynamic> json) => ReferralInvite(
        id: json['id'] as String,
        referrerUserId: json['referrerUserId'] as String,
        referralCode: json['referralCode'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
        expiresAt: DateTime.parse(json['expiresAt'] as String).toUtc(),
        status: InviteStatus.values.firstWhere(
          (e) => e.name == (json['status'] as String? ?? 'pending'),
          orElse: () => InviteStatus.pending,
        ),
        redeemedBy: json['redeemedBy'] as String?,
        redeemedAt: json['redeemedAt'] != null
            ? DateTime.parse(json['redeemedAt'] as String).toUtc()
            : null,
        inviteeName: json['inviteeName'] as String?,
        inviteeEmail: json['inviteeEmail'] as String?,
        isSynced: (json['isSynced'] as bool?) ?? false,
        serverId: json['serverId'] as String?,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );

  @override
  List<Object?> get props => [
        id,
        referrerUserId,
        referralCode,
        createdAt,
        expiresAt,
        status,
        redeemedBy,
        redeemedAt,
        inviteeName,
        inviteeEmail,
        isSynced,
        serverId,
        metadata,
      ];

  @override
  String toString() {
    return 'ReferralInvite(id: $id, code: $referralCode, status: ${status.name}, '
        'expires: $expiresAt, redeemed: $isRedeemed)';
  }
}

class ReferralScanEvent extends Equatable {
  final String code;
  final String? scannerUserId; // who scanned (may be null if not signed in)
  final DateTime scannedAt;
  final String source; // "qr" | "link" | "manual"
  final String? campaignId; // optional attribution tag

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

  factory ReferralScanEvent.fromJson(Map<String, dynamic> json) =>
      ReferralScanEvent(
        code: json['code'] as String,
        scannerUserId: json['scannerUserId'] as String?,
        scannedAt: DateTime.parse(json['scannedAt'] as String).toUtc(),
        source: (json['source'] as String?) ?? 'qr',
        campaignId: json['campaignId'] as String?,
      );

  @override
  List<Object?> get props =>
      [code, scannerUserId, scannedAt, source, campaignId];
}
