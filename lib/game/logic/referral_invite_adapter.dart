import 'package:hive/hive.dart';
import '../models/referral_models.dart';

part 'referral_invite_adapter.g.dart';

/// Hive Type Adapter for ReferralInvite
/// TypeId: 10 (change if this conflicts with other adapters)
@HiveType(typeId: 10)
class ReferralInviteHive extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String referrerUserId;

  @HiveField(2)
  String referralCode;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  DateTime expiresAt;

  @HiveField(5)
  String status; // 'pending', 'redeemed', 'expired'

  @HiveField(6)
  String? redeemedBy;

  @HiveField(7)
  DateTime? redeemedAt;

  @HiveField(8)
  String? inviteeName;

  @HiveField(9)
  String? inviteeEmail;

  @HiveField(10)
  bool isSynced;

  @HiveField(11)
  String? serverId;

  @HiveField(12)
  Map<dynamic, dynamic>? metadata;

  ReferralInviteHive({
    required this.id,
    required this.referrerUserId,
    required this.referralCode,
    required this.createdAt,
    required this.expiresAt,
    this.status = 'pending',
    this.redeemedBy,
    this.redeemedAt,
    this.inviteeName,
    this.inviteeEmail,
    this.isSynced = false,
    this.serverId,
    this.metadata,
  });

  /// Convert from ReferralInvite model to Hive object
  factory ReferralInviteHive.fromModel(ReferralInvite invite) {
    return ReferralInviteHive(
      id: invite.id,
      referrerUserId: invite.referrerUserId,
      referralCode: invite.referralCode,
      createdAt: invite.createdAt,
      expiresAt: invite.expiresAt,
      status: invite.status.name,
      redeemedBy: invite.redeemedBy,
      redeemedAt: invite.redeemedAt,
      inviteeName: invite.inviteeName,
      inviteeEmail: invite.inviteeEmail,
      isSynced: invite.isSynced,
      serverId: invite.serverId,
      metadata: invite.metadata,
    );
  }

  /// Convert to ReferralInvite model
  ReferralInvite toModel() {
    return ReferralInvite(
      id: id,
      referrerUserId: referrerUserId,
      referralCode: referralCode,
      createdAt: createdAt,
      expiresAt: expiresAt,
      status: InviteStatus.values.firstWhere(
        (e) => e.name == status,
        orElse: () => InviteStatus.pending,
      ),
      redeemedBy: redeemedBy,
      redeemedAt: redeemedAt,
      inviteeName: inviteeName,
      inviteeEmail: inviteeEmail,
      isSynced: isSynced,
      serverId: serverId,
      metadata: metadata?.cast<String, dynamic>(),
    );
  }
}
