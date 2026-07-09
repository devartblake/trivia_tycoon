/// Data Transfer Objects for the Party API.
///
/// Shapes mirror the backend contracts in
/// Synaptix.Shared.Contracts/Dtos/SocialDtos.cs:
/// - PartyRosterDto  {partyId, leaderPlayerId, status, members}
/// - PartyMemberDto  {playerId, role, joinedAtUtc}
/// - PartyInviteDto  {inviteId, partyId, fromPlayerId, toPlayerId, status,
///                    createdAtUtc, respondedAtUtc}
library;

/// A party roster — returned by POST /party and GET /party/{id}.
class PartyRoster {
  final String partyId;
  final String leaderPlayerId;

  /// Open | Queued | Matched | Closed
  final String status;
  final List<PartyMember> members;

  const PartyRoster({
    required this.partyId,
    required this.leaderPlayerId,
    required this.status,
    required this.members,
  });

  factory PartyRoster.fromJson(Map<String, dynamic> json) {
    final membersList = json['members'] as List<dynamic>? ?? const [];
    return PartyRoster(
      partyId: json['partyId']?.toString() ?? '',
      leaderPlayerId: json['leaderPlayerId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Open',
      members: membersList
          .whereType<Map>()
          .map((m) => PartyMember.fromJson(Map<String, dynamic>.from(m)))
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
        'partyId': partyId,
        'leaderPlayerId': leaderPlayerId,
        'status': status,
        'members': members.map((m) => m.toJson()).toList(growable: false),
      };
}

/// A member of a party.
class PartyMember {
  final String playerId;
  final String role;
  final DateTime joinedAtUtc;

  const PartyMember({
    required this.playerId,
    required this.role,
    required this.joinedAtUtc,
  });

  factory PartyMember.fromJson(Map<String, dynamic> json) {
    return PartyMember(
      playerId: json['playerId']?.toString() ?? '',
      role: json['role']?.toString() ?? 'member',
      joinedAtUtc:
          DateTime.tryParse(json['joinedAtUtc']?.toString() ?? '')?.toUtc() ??
              DateTime.now().toUtc(),
    );
  }

  Map<String, dynamic> toJson() => {
        'playerId': playerId,
        'role': role,
        'joinedAtUtc': joinedAtUtc.toIso8601String(),
      };
}

/// A party invitation.
class PartyInvite {
  final String inviteId;
  final String partyId;
  final String fromPlayerId;
  final String toPlayerId;

  /// Pending | Accepted | Declined | Cancelled
  final String status;
  final DateTime createdAtUtc;
  final DateTime? respondedAtUtc;

  const PartyInvite({
    required this.inviteId,
    required this.partyId,
    required this.fromPlayerId,
    required this.toPlayerId,
    required this.status,
    required this.createdAtUtc,
    this.respondedAtUtc,
  });

  factory PartyInvite.fromJson(Map<String, dynamic> json) {
    return PartyInvite(
      inviteId: json['inviteId']?.toString() ?? '',
      partyId: json['partyId']?.toString() ?? '',
      fromPlayerId: json['fromPlayerId']?.toString() ?? '',
      toPlayerId: json['toPlayerId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Pending',
      createdAtUtc:
          DateTime.tryParse(json['createdAtUtc']?.toString() ?? '')?.toUtc() ??
              DateTime.now().toUtc(),
      respondedAtUtc:
          DateTime.tryParse(json['respondedAtUtc']?.toString() ?? '')?.toUtc(),
    );
  }

  Map<String, dynamic> toJson() => {
        'inviteId': inviteId,
        'partyId': partyId,
        'fromPlayerId': fromPlayerId,
        'toPlayerId': toPlayerId,
        'status': status,
        'createdAtUtc': createdAtUtc.toIso8601String(),
        'respondedAtUtc': respondedAtUtc?.toIso8601String(),
      };
}
