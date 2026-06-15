/// DTOs for the Party / group-play feature (`/party` REST + MatchHub push events).
///
/// REST responses use camelCase; SignalR push payloads use PascalCase
/// (the hub serializer sets PropertyNamingPolicy = null), so the push DTOs
/// read PascalCase keys first and fall back to camelCase.
library;

class PartyMemberDto {
  final String playerId;
  final String role;
  final DateTime joinedAtUtc;

  const PartyMemberDto({
    required this.playerId,
    required this.role,
    required this.joinedAtUtc,
  });

  factory PartyMemberDto.fromJson(Map<String, dynamic> j) => PartyMemberDto(
        playerId: (j['playerId'] ?? j['PlayerId']) as String,
        role: (j['role'] ?? j['Role']) as String? ?? 'member',
        joinedAtUtc: DateTime.tryParse(
                (j['joinedAtUtc'] ?? j['JoinedAtUtc']) as String? ?? '') ??
            DateTime.now(),
      );
}

class PartyRosterDto {
  final String partyId;
  final String leaderPlayerId;

  /// Open | Queued | Matched | Closed
  final String status;
  final List<PartyMemberDto> members;

  const PartyRosterDto({
    required this.partyId,
    required this.leaderPlayerId,
    required this.status,
    required this.members,
  });

  factory PartyRosterDto.fromJson(Map<String, dynamic> j) => PartyRosterDto(
        partyId: (j['partyId'] ?? j['PartyId']) as String,
        leaderPlayerId:
            (j['leaderPlayerId'] ?? j['LeaderPlayerId']) as String,
        status: (j['status'] ?? j['Status']) as String? ?? 'Open',
        members: ((j['members'] ?? j['Members']) as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>()
            .map(PartyMemberDto.fromJson)
            .toList(),
      );
}

class PartyInviteDto {
  final String inviteId;
  final String partyId;
  final String fromPlayerId;
  final String toPlayerId;

  /// Pending | Accepted | Declined | Cancelled
  final String status;
  final DateTime createdAtUtc;
  final DateTime? respondedAtUtc;

  const PartyInviteDto({
    required this.inviteId,
    required this.partyId,
    required this.fromPlayerId,
    required this.toPlayerId,
    required this.status,
    required this.createdAtUtc,
    this.respondedAtUtc,
  });

  factory PartyInviteDto.fromJson(Map<String, dynamic> j) => PartyInviteDto(
        inviteId: (j['inviteId'] ?? j['InviteId']) as String,
        partyId: (j['partyId'] ?? j['PartyId']) as String,
        fromPlayerId: (j['fromPlayerId'] ?? j['FromPlayerId']) as String,
        toPlayerId: (j['toPlayerId'] ?? j['ToPlayerId']) as String,
        status: (j['status'] ?? j['Status']) as String? ?? 'Pending',
        createdAtUtc: DateTime.tryParse(
                (j['createdAtUtc'] ?? j['CreatedAtUtc']) as String? ?? '') ??
            DateTime.now(),
        respondedAtUtc: DateTime.tryParse(
            (j['respondedAtUtc'] ?? j['RespondedAtUtc']) as String? ?? ''),
      );
}

class PartyInvitesListDto {
  final int page;
  final int pageSize;
  final int total;
  final List<PartyInviteDto> items;

  const PartyInvitesListDto({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.items,
  });

  factory PartyInvitesListDto.fromJson(Map<String, dynamic> j) =>
      PartyInvitesListDto(
        page: (j['page'] ?? j['Page']) as int? ?? 1,
        pageSize: (j['pageSize'] ?? j['PageSize']) as int? ?? 50,
        total: (j['total'] ?? j['Total']) as int? ?? 0,
        items: ((j['items'] ?? j['Items']) as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>()
            .map(PartyInviteDto.fromJson)
            .toList(),
      );
}

/// Result of `POST /party/{id}/enqueue` — `status` is Queued | Matched | ...
class PartyEnqueueResultDto {
  final String status;
  final String? ticketId;
  final Map<String, dynamic> raw;

  const PartyEnqueueResultDto({
    required this.status,
    this.ticketId,
    this.raw = const {},
  });

  factory PartyEnqueueResultDto.fromJson(Map<String, dynamic> j) =>
      PartyEnqueueResultDto(
        status: (j['status'] ?? j['Status']) as String? ?? 'Unknown',
        ticketId: (j['ticketId'] ?? j['TicketId']) as String?,
        raw: j,
      );
}

// ── MatchHub push events (PascalCase payloads) ──────────────────────────────

/// `party.matched` — opponent found; the server has auto-joined this client to
/// the `match:{matchId}` group.
class PartyMatchedDto {
  final String ticketId;
  final String partyId;
  final String opponentPartyId;
  final String matchId;
  final String mode;
  final int tier;
  final String scope;

  const PartyMatchedDto({
    required this.ticketId,
    required this.partyId,
    required this.opponentPartyId,
    required this.matchId,
    required this.mode,
    required this.tier,
    required this.scope,
  });

  factory PartyMatchedDto.fromJson(Map<String, dynamic> j) => PartyMatchedDto(
        ticketId: (j['TicketId'] ?? j['ticketId']) as String? ?? '',
        partyId: (j['PartyId'] ?? j['partyId']) as String? ?? '',
        opponentPartyId:
            (j['OpponentPartyId'] ?? j['opponentPartyId']) as String? ?? '',
        matchId: (j['MatchId'] ?? j['matchId']) as String? ?? '',
        mode: (j['Mode'] ?? j['mode']) as String? ?? '',
        tier: (j['Tier'] ?? j['tier']) as int? ?? 0,
        scope: (j['Scope'] ?? j['scope']) as String? ?? '',
      );
}

/// `party.roster.updated` — `{ Roster, OnlinePlayerIds }`.
class PartyRosterUpdatedDto {
  final PartyRosterDto roster;
  final List<String> onlinePlayerIds;

  const PartyRosterUpdatedDto({
    required this.roster,
    required this.onlinePlayerIds,
  });

  factory PartyRosterUpdatedDto.fromJson(Map<String, dynamic> j) =>
      PartyRosterUpdatedDto(
        roster: PartyRosterDto.fromJson(
            (j['Roster'] ?? j['roster']) as Map<String, dynamic>),
        onlinePlayerIds:
            ((j['OnlinePlayerIds'] ?? j['onlinePlayerIds']) as List<dynamic>? ??
                    const [])
                .map((e) => e.toString())
                .toList(),
      );
}

/// `party.closed` — `{ PartyId, MatchId, Reason }`.
class PartyClosedDto {
  final String partyId;
  final String matchId;
  final String reason;

  const PartyClosedDto({
    required this.partyId,
    required this.matchId,
    required this.reason,
  });

  factory PartyClosedDto.fromJson(Map<String, dynamic> j) => PartyClosedDto(
        partyId: (j['PartyId'] ?? j['partyId']) as String? ?? '',
        matchId: (j['MatchId'] ?? j['matchId']) as String? ?? '',
        reason: (j['Reason'] ?? j['reason']) as String? ?? '',
      );
}
