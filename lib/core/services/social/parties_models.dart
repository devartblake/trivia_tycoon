/// Data Transfer Objects and Domain Models for Parties API
///
/// This file defines all request/response shapes for party operations:
/// - Party creation and management
/// - Party member management
/// - Party invitations
library;

/// Response for a single party
class PartyResponse {
  final String partyId;
  final String name;
  final String? description;
  final String ownerId;
  final int memberCount;
  final int maxMembers;
  final String status; // 'active', 'completed', 'disbanded'
  final String? gameMode;
  final DateTime createdAtUtc;

  const PartyResponse({
    required this.partyId,
    required this.name,
    this.description,
    required this.ownerId,
    required this.memberCount,
    required this.maxMembers,
    required this.status,
    this.gameMode,
    required this.createdAtUtc,
  });

  factory PartyResponse.fromJson(Map<String, dynamic> json) {
    return PartyResponse(
      partyId: json['partyId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description'] as String?,
      ownerId: json['ownerId']?.toString() ?? '',
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
      maxMembers: (json['maxMembers'] as num?)?.toInt() ?? 4,
      status: json['status']?.toString() ?? 'active',
      gameMode: json['gameMode'] as String?,
      createdAtUtc: DateTime.tryParse(json['createdAtUtc']?.toString() ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
    );
  }

  Map<String, dynamic> toJson() => {
    'partyId': partyId,
    'name': name,
    'description': description,
    'ownerId': ownerId,
    'memberCount': memberCount,
    'maxMembers': maxMembers,
    'status': status,
    'gameMode': gameMode,
    'createdAtUtc': createdAtUtc.toIso8601String(),
  };
}

/// Detailed party information including members and pending invites
class PartyDetailResponse {
  final String partyId;
  final String name;
  final String? description;
  final String ownerId;
  final String ownerUsername;
  final List<PartyMember> members;
  final List<PartyInvite> pendingInvites;
  final int maxMembers;
  final String status;
  final String? gameMode;
  final DateTime createdAtUtc;

  const PartyDetailResponse({
    required this.partyId,
    required this.name,
    this.description,
    required this.ownerId,
    required this.ownerUsername,
    required this.members,
    required this.pendingInvites,
    required this.maxMembers,
    required this.status,
    this.gameMode,
    required this.createdAtUtc,
  });

  factory PartyDetailResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> membersList = json['members'] as List<dynamic>? ?? [];
    final List<dynamic> invitesList = json['pendingInvites'] as List<dynamic>? ?? [];

    return PartyDetailResponse(
      partyId: json['partyId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description'] as String?,
      ownerId: json['ownerId']?.toString() ?? '',
      ownerUsername: json['ownerUsername']?.toString() ?? 'Unknown',
      members: membersList
          .map((m) => PartyMember.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
      pendingInvites: invitesList
          .map((i) => PartyInvite.fromJson(Map<String, dynamic>.from(i)))
          .toList(),
      maxMembers: (json['maxMembers'] as num?)?.toInt() ?? 4,
      status: json['status']?.toString() ?? 'active',
      gameMode: json['gameMode'] as String?,
      createdAtUtc: DateTime.tryParse(json['createdAtUtc']?.toString() ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
    );
  }

  Map<String, dynamic> toJson() => {
    'partyId': partyId,
    'name': name,
    'description': description,
    'ownerId': ownerId,
    'ownerUsername': ownerUsername,
    'members': members.map((m) => m.toJson()).toList(),
    'pendingInvites': pendingInvites.map((i) => i.toJson()).toList(),
    'maxMembers': maxMembers,
    'status': status,
    'gameMode': gameMode,
    'createdAtUtc': createdAtUtc.toIso8601String(),
  };
}

/// Party member information
class PartyMember {
  final String playerId;
  final String username;
  final String? avatarUrl;
  final String role; // 'owner', 'member'
  final DateTime joinedAtUtc;
  final bool isReady;

  const PartyMember({
    required this.playerId,
    required this.username,
    this.avatarUrl,
    required this.role,
    required this.joinedAtUtc,
    required this.isReady,
  });

  factory PartyMember.fromJson(Map<String, dynamic> json) {
    return PartyMember(
      playerId: json['playerId']?.toString() ?? '',
      username: json['username']?.toString() ?? 'Unknown',
      avatarUrl: json['avatarUrl'] as String?,
      role: json['role']?.toString() ?? 'member',
      joinedAtUtc: DateTime.tryParse(json['joinedAtUtc']?.toString() ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
      isReady: (json['isReady'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'playerId': playerId,
    'username': username,
    'avatarUrl': avatarUrl,
    'role': role,
    'joinedAtUtc': joinedAtUtc.toIso8601String(),
    'isReady': isReady,
  };
}

/// Pending party invitation
class PartyInvite {
  final String inviteId;
  final String toPlayerId;
  final String toUsername;
  final String? toAvatarUrl;
  final DateTime sentAtUtc;

  const PartyInvite({
    required this.inviteId,
    required this.toPlayerId,
    required this.toUsername,
    this.toAvatarUrl,
    required this.sentAtUtc,
  });

  factory PartyInvite.fromJson(Map<String, dynamic> json) {
    return PartyInvite(
      inviteId: json['inviteId']?.toString() ?? '',
      toPlayerId: json['toPlayerId']?.toString() ?? '',
      toUsername: json['toUsername']?.toString() ?? 'Unknown',
      toAvatarUrl: json['toAvatarUrl'] as String?,
      sentAtUtc: DateTime.tryParse(json['sentAtUtc']?.toString() ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
    );
  }

  Map<String, dynamic> toJson() => {
    'inviteId': inviteId,
    'toPlayerId': toPlayerId,
    'toUsername': toUsername,
    'toAvatarUrl': toAvatarUrl,
    'sentAtUtc': sentAtUtc.toIso8601String(),
  };
}

/// Response containing list of parties
class PartiesListResponse {
  final List<PartyResponse> parties;
  final int totalCount;
  final int page;
  final int pageSize;

  const PartiesListResponse({
    required this.parties,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  factory PartiesListResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> partiesList = json['parties'] as List<dynamic>? ?? [];
    return PartiesListResponse(
      parties: partiesList
          .map((p) => PartyResponse.fromJson(Map<String, dynamic>.from(p)))
          .toList(),
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 20,
    );
  }

  Map<String, dynamic> toJson() => {
    'parties': parties.map((p) => p.toJson()).toList(),
    'totalCount': totalCount,
    'page': page,
    'pageSize': pageSize,
  };
}
