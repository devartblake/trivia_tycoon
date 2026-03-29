import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

enum GroupType {
  privateGroup,
  publicGroup,
  gameSession,
  spectatorRoom;

  String get displayName {
    switch (this) {
      case GroupType.privateGroup:
        return 'Private Group';
      case GroupType.publicGroup:
        return 'Public Group';
      case GroupType.gameSession:
        return 'Game Session';
      case GroupType.spectatorRoom:
        return 'Spectator Room';
    }
  }
}

enum GroupRole {
  owner,
  admin,
  moderator,
  member,
  spectator;

  String get displayName {
    switch (this) {
      case GroupRole.owner:
        return 'Owner';
      case GroupRole.admin:
        return 'Admin';
      case GroupRole.moderator:
        return 'Moderator';
      case GroupRole.member:
        return 'Member';
      case GroupRole.spectator:
        return 'Spectator';
    }
  }

  bool get canManageMembers => [owner, admin].contains(this);
  bool get canModerateChat => [owner, admin, moderator].contains(this);
  bool get canSendMessages => this != GroupRole.spectator;
}

class GroupMember {
  final String userId;
  final String displayName;
  final String? avatar;
  final GroupRole role;
  final DateTime joinedAt;
  final bool isOnline;
  final DateTime? lastSeen;

  const GroupMember({
    required this.userId,
    required this.displayName,
    this.avatar,
    required this.role,
    required this.joinedAt,
    this.isOnline = false,
    this.lastSeen,
  });

  GroupMember copyWith({
    String? userId,
    String? displayName,
    String? avatar,
    GroupRole? role,
    DateTime? joinedAt,
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return GroupMember(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      if (avatar != null) 'avatar': avatar,
      'role': role.name,
      'joinedAt': joinedAt.toIso8601String(),
      'isOnline': isOnline,
      if (lastSeen != null) 'lastSeen': lastSeen!.toIso8601String(),
    };
  }

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      avatar: json['avatar'] as String?,
      role: GroupRole.values.byName(json['role'] as String),
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeen: json['lastSeen'] != null
          ? DateTime.parse(json['lastSeen'] as String)
          : null,
    );
  }
}

class GroupChat {
  final String id;
  final String name;
  final String? description;
  final String? avatar;
  final GroupType type;
  final String ownerId;
  final List<GroupMember> members;
  final DateTime createdAt;
  final DateTime lastActivity;
  final bool isActive;
  final Map<String, dynamic>? settings;

  const GroupChat({
    required this.id,
    required this.name,
    this.description,
    this.avatar,
    required this.type,
    required this.ownerId,
    required this.members,
    required this.createdAt,
    required this.lastActivity,
    this.isActive = true,
    this.settings,
  });

  int get memberCount => members.length;
  int get onlineMemberCount => members.where((m) => m.isOnline).length;

  GroupMember? getMember(String userId) {
    try {
      return members.firstWhere((member) => member.userId == userId);
    } catch (e) {
      return null;
    }
  }

  List<GroupMember> get onlineMembers =>
      members.where((member) => member.isOnline).toList();

  List<GroupMember> get admins =>
      members.where((member) => member.role.canManageMembers).toList();

  bool canUserPerformAction(String userId, GroupRole requiredRole) {
    final member = getMember(userId);
    if (member == null) return false;

    return member.role.index <= requiredRole.index;
  }

  GroupChat copyWith({
    String? id,
    String? name,
    String? description,
    String? avatar,
    GroupType? type,
    String? ownerId,
    List<GroupMember>? members,
    DateTime? createdAt,
    DateTime? lastActivity,
    bool? isActive,
    Map<String, dynamic>? settings,
  }) {
    return GroupChat(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      avatar: avatar ?? this.avatar,
      type: type ?? this.type,
      ownerId: ownerId ?? this.ownerId,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
      lastActivity: lastActivity ?? this.lastActivity,
      isActive: isActive ?? this.isActive,
      settings: settings ?? this.settings,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      if (avatar != null) 'avatar': avatar,
      'type': type.name,
      'ownerId': ownerId,
      'members': members.map((m) => m.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'lastActivity': lastActivity.toIso8601String(),
      'isActive': isActive,
      if (settings != null) 'settings': settings,
    };
  }

  factory GroupChat.fromJson(Map<String, dynamic> json) {
    return GroupChat(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      avatar: json['avatar'] as String?,
      type: GroupType.values.byName(json['type'] as String),
      ownerId: json['ownerId'] as String,
      members: (json['members'] as List)
          .map((m) => GroupMember.fromJson(m as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastActivity: DateTime.parse(json['lastActivity'] as String),
      isActive: json['isActive'] as bool? ?? true,
      settings: json['settings'] as Map<String, dynamic>?,
    );
  }
}

class GroupChatService extends ChangeNotifier {
  static final GroupChatService _instance = GroupChatService._internal();
  factory GroupChatService() => _instance;
  GroupChatService._internal();

  final Map<String, GroupChat> _groups = {};
  final Map<String, StreamController<GroupChat>> _groupStreams = {};
  final Map<String, StreamController<List<GroupMember>>> _memberStreams = {};

  Timer? _presenceUpdateTimer;

  // Settings
  int _maxGroupSize = 50;
  int _maxGroupsPerUser = 20;
  bool _allowPublicGroups = true;
  Duration _inactiveGroupCleanup = const Duration(days: 30);

  // Getters
  Map<String, GroupChat> get allGroups => Map.unmodifiable(_groups);
  List<GroupChat> get activeGroups => _groups.values.where((g) => g.isActive).toList();

  void initialize() {
    _startPresenceUpdates();
    LogManager.debug('GroupChatService initialized');
  }

  void dispose() {
    _presenceUpdateTimer?.cancel();
    for (final controller in _groupStreams.values) {
      controller.close();
    }
    for (final controller in _memberStreams.values) {
      controller.close();
    }
    _groupStreams.clear();
    _memberStreams.clear();
    super.dispose();
  }

  // Group management
  Future<GroupChat?> createGroup({
    required String name,
    String? description,
    required GroupType type,
    required String ownerId,
    required String ownerDisplayName,
    List<String>? initialMemberIds,
    Map<String, dynamic>? settings,
  }) async {
    if (name.trim().isEmpty) return null;

    final groupId = _generateGroupId();
    final now = DateTime.now();

    // Create owner as first member
    final owner = GroupMember(
      userId: ownerId,
      displayName: ownerDisplayName,
      role: GroupRole.owner,
      joinedAt: now,
      isOnline: true,
    );

    final members = <GroupMember>[owner];

    // Add initial members if provided
    if (initialMemberIds != null) {
      for (final memberId in initialMemberIds) {
        if (memberId != ownerId && members.length < _maxGroupSize) {
          // In a real app, you'd fetch user display names
          members.add(GroupMember(
            userId: memberId,
            displayName: 'User $memberId', // Placeholder
            role: GroupRole.member,
            joinedAt: now,
          ));
        }
      }
    }

    final group = GroupChat(
      id: groupId,
      name: name,
      description: description,
      type: type,
      ownerId: ownerId,
      members: members,
      createdAt: now,
      lastActivity: now,
      settings: settings,
    );

    _groups[groupId] = group;

    LogManager.debug('Created group "$name" with ${members.length} members');
    notifyListeners();
    _broadcastGroupUpdate(groupId);

    return group;
  }

  Future<bool> joinGroup(String groupId, String userId, String displayName) async {
    final group = _groups[groupId];
    if (group == null || !group.isActive) return false;

    // Check if user is already a member
    if (group.getMember(userId) != null) return false;

    // Check group size limit
    if (group.members.length >= _maxGroupSize) return false;

    // Check if group is public or user is invited
    if (group.type == GroupType.privateGroup) {
      // In a real app, you'd check invitations
      return false;
    }

    final newMember = GroupMember(
      userId: userId,
      displayName: displayName,
      role: GroupRole.member,
      joinedAt: DateTime.now(),
      isOnline: true,
    );

    final updatedMembers = List<GroupMember>.from(group.members)..add(newMember);

    _groups[groupId] = group.copyWith(
      members: updatedMembers,
      lastActivity: DateTime.now(),
    );

    LogManager.debug('User $displayName joined group ${group.name}');
    notifyListeners();
    _broadcastGroupUpdate(groupId);
    _broadcastMemberUpdate(groupId);

    return true;
  }

  Future<bool> leaveGroup(String groupId, String userId) async {
    final group = _groups[groupId];
    if (group == null) return false;

    final member = group.getMember(userId);
    if (member == null) return false;

    // If owner is leaving, transfer ownership or delete group
    if (member.role == GroupRole.owner) {
      final admins = group.members.where((m) => m.role == GroupRole.admin).toList();
      if (admins.isNotEmpty) {
        // Transfer ownership to first admin
        final newOwner = admins.first.copyWith(role: GroupRole.owner);
        final updatedMembers = group.members
            .where((m) => m.userId != userId)
            .map((m) => m.userId == newOwner.userId ? newOwner : m)
            .toList();

        _groups[groupId] = group.copyWith(
          ownerId: newOwner.userId,
          members: updatedMembers,
          lastActivity: DateTime.now(),
        );
      } else {
        // Delete group if no admins
        return await deleteGroup(groupId, userId);
      }
    } else {
      // Regular member leaving
      final updatedMembers = group.members
          .where((m) => m.userId != userId)
          .toList();

      _groups[groupId] = group.copyWith(
        members: updatedMembers,
        lastActivity: DateTime.now(),
      );
    }

    LogManager.debug('User $userId left group ${group.name}');
    notifyListeners();
    _broadcastGroupUpdate(groupId);
    _broadcastMemberUpdate(groupId);

    return true;
  }

  Future<bool> deleteGroup(String groupId, String userId) async {
    final group = _groups[groupId];
    if (group == null) return false;

    final member = group.getMember(userId);
    if (member == null || member.role != GroupRole.owner) return false;

    _groups.remove(groupId);
    _groupStreams[groupId]?.close();
    _memberStreams[groupId]?.close();
    _groupStreams.remove(groupId);
    _memberStreams.remove(groupId);

    LogManager.debug('Deleted group ${group.name}');
    notifyListeners();

    return true;
  }

  // Member management
  Future<bool> updateMemberRole(
      String groupId,
      String targetUserId,
      GroupRole newRole,
      String requesterId,
      ) async {
    final group = _groups[groupId];
    if (group == null) return false;

    final requester = group.getMember(requesterId);
    final targetMember = group.getMember(targetUserId);

    if (requester == null || targetMember == null) return false;
    if (!requester.role.canManageMembers) return false;
    if (targetMember.role == GroupRole.owner) return false;

    final updatedMembers = group.members.map((member) {
      if (member.userId == targetUserId) {
        return member.copyWith(role: newRole);
      }
      return member;
    }).toList();

    _groups[groupId] = group.copyWith(
      members: updatedMembers,
      lastActivity: DateTime.now(),
    );

    LogManager.debug('Updated ${targetMember.displayName} role to ${newRole.displayName}');
    notifyListeners();
    _broadcastGroupUpdate(groupId);
    _broadcastMemberUpdate(groupId);

    return true;
  }

  Future<bool> kickMember(
      String groupId,
      String targetUserId,
      String requesterId,
      ) async {
    final group = _groups[groupId];
    if (group == null) return false;

    final requester = group.getMember(requesterId);
    final targetMember = group.getMember(targetUserId);

    if (requester == null || targetMember == null) return false;
    if (!requester.role.canManageMembers) return false;
    if (targetMember.role == GroupRole.owner) return false;
    if (targetMember.role.index <= requester.role.index && requester.role != GroupRole.owner) {
      return false; // Can't kick someone with equal or higher role
    }

    return await leaveGroup(groupId, targetUserId);
  }

  // Presence management
  void updateMemberPresence(String userId, bool isOnline) {
    bool hasUpdates = false;

    for (final entry in _groups.entries) {
      final groupId = entry.key;
      final group = entry.value;

      final member = group.getMember(userId);
      if (member != null) {
        final updatedMembers = group.members.map((m) {
          if (m.userId == userId) {
            return m.copyWith(
              isOnline: isOnline,
              lastSeen: isOnline ? null : DateTime.now(),
            );
          }
          return m;
        }).toList();

        _groups[groupId] = group.copyWith(members: updatedMembers);
        _broadcastMemberUpdate(groupId);
        hasUpdates = true;
      }
    }

    if (hasUpdates) {
      notifyListeners();
    }
  }

  void _startPresenceUpdates() {
    _presenceUpdateTimer = Timer.periodic(
      const Duration(seconds: 30),
          (_) => _cleanupInactiveGroups(),
    );
  }

  void _cleanupInactiveGroups() {
    final cutoff = DateTime.now().subtract(_inactiveGroupCleanup);
    final toRemove = <String>[];

    for (final entry in _groups.entries) {
      if (entry.value.lastActivity.isBefore(cutoff) &&
          entry.value.type != GroupType.privateGroup) {
        toRemove.add(entry.key);
      }
    }

    for (final groupId in toRemove) {
      _groups.remove(groupId);
      _groupStreams[groupId]?.close();
      _memberStreams[groupId]?.close();
      _groupStreams.remove(groupId);
      _memberStreams.remove(groupId);
    }

    if (toRemove.isNotEmpty) {
      LogManager.debug('Cleaned up ${toRemove.length} inactive groups');
      notifyListeners();
    }
  }

  // Query methods
  GroupChat? getGroup(String groupId) => _groups[groupId];

  List<GroupChat> getUserGroups(String userId) {
    return _groups.values
        .where((group) => group.getMember(userId) != null)
        .toList()
      ..sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
  }

  List<GroupChat> getActiveGameSessions() {
    return _groups.values
        .where((group) =>
    group.type == GroupType.gameSession &&
        group.isActive &&
        group.onlineMemberCount > 0)
        .toList()
      ..sort((a, b) => b.onlineMemberCount.compareTo(a.onlineMemberCount));
  }

  List<GroupChat> getPublicGroups() {
    if (!_allowPublicGroups) return [];

    return _groups.values
        .where((group) =>
    group.type == GroupType.publicGroup &&
        group.isActive)
        .toList()
      ..sort((a, b) => b.memberCount.compareTo(a.memberCount));
  }

  List<GroupChat> searchGroups(String query) {
    final lowerQuery = query.toLowerCase();
    return _groups.values
        .where((group) =>
    group.name.toLowerCase().contains(lowerQuery) ||
        (group.description?.toLowerCase().contains(lowerQuery) ?? false))
        .toList()
      ..sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
  }

  // Streaming
  Stream<GroupChat> watchGroup(String groupId) {
    _groupStreams[groupId] ??= StreamController<GroupChat>.broadcast();
    return _groupStreams[groupId]!.stream;
  }

  Stream<List<GroupMember>> watchGroupMembers(String groupId) {
    _memberStreams[groupId] ??= StreamController<List<GroupMember>>.broadcast();
    return _memberStreams[groupId]!.stream;
  }

  void _broadcastGroupUpdate(String groupId) {
    final group = _groups[groupId];
    if (group != null) {
      final controller = _groupStreams[groupId];
      if (controller != null && !controller.isClosed) {
        controller.add(group);
      }
    }
  }

  void _broadcastMemberUpdate(String groupId) {
    final group = _groups[groupId];
    if (group != null) {
      final controller = _memberStreams[groupId];
      if (controller != null && !controller.isClosed) {
        controller.add(group.members);
      }
    }
  }

  // Group settings
  Future<bool> updateGroupSettings({
    required String groupId,
    String? name,
    String? description,
    String? avatar,
    Map<String, dynamic>? settings,
    required String requesterId,
  }) async {
    final group = _groups[groupId];
    if (group == null) return false;

    final requester = group.getMember(requesterId);
    if (requester == null || !requester.role.canManageMembers) return false;

    _groups[groupId] = group.copyWith(
      name: name ?? group.name,
      description: description ?? group.description,
      avatar: avatar ?? group.avatar,
      settings: settings ?? group.settings,
      lastActivity: DateTime.now(),
    );

    LogManager.debug('Updated group settings for ${group.name}');
    notifyListeners();
    _broadcastGroupUpdate(groupId);

    return true;
  }

  // Utility methods
  String _generateGroupId() {
    return 'group_${DateTime.now().millisecondsSinceEpoch}_${_groups.length}';
  }

  // Invite system (placeholder for future implementation)
  Future<bool> inviteToGroup(
      String groupId,
      String targetUserId,
      String inviterId,
      ) async {
    final group = _groups[groupId];
    if (group == null) return false;

    final inviter = group.getMember(inviterId);
    if (inviter == null || !inviter.role.canManageMembers) return false;

    // In a real app, this would create an invitation that the user can accept/decline
    LogManager.debug('Invitation sent to $targetUserId for group ${group.name}');
    return true;
  }

  // Analytics
  Map<String, dynamic> getGroupAnalytics(String groupId) {
    final group = _groups[groupId];
    if (group == null) return {};

    final now = DateTime.now();
    final activeMembers = group.members
        .where((m) => m.lastSeen?.isAfter(now.subtract(const Duration(days: 7))) ?? m.isOnline)
        .length;

    return {
      'totalMembers': group.memberCount,
      'onlineMembers': group.onlineMemberCount,
      'activeMembers': activeMembers,
      'groupAge': now.difference(group.createdAt).inDays,
      'lastActivity': now.difference(group.lastActivity).inMinutes,
      'roleDistribution': _getRoleDistribution(group),
    };
  }

  Map<String, int> _getRoleDistribution(GroupChat group) {
    final distribution = <String, int>{};
    for (final member in group.members) {
      distribution[member.role.name] = (distribution[member.role.name] ?? 0) + 1;
    }
    return distribution;
  }

  Map<String, dynamic> getServiceAnalytics() {
    final totalGroups = _groups.length;
    final activeGroupsCount = activeGroups.length;
    final totalMembers = _groups.values.fold<int>(
      0,
          (sum, group) => sum + group.memberCount,
    );
    final averageMembersPerGroup = totalGroups > 0 ? totalMembers / totalGroups : 0;

    final groupTypeDistribution = <String, int>{};
    for (final group in _groups.values) {
      groupTypeDistribution[group.type.name] =
          (groupTypeDistribution[group.type.name] ?? 0) + 1;
    }

    return {
      'totalGroups': totalGroups,
      'activeGroups': activeGroupsCount,
      'totalMembers': totalMembers,
      'averageMembersPerGroup': averageMembersPerGroup,
      'groupTypeDistribution': groupTypeDistribution,
      'settings': {
        'maxGroupSize': _maxGroupSize,
        'maxGroupsPerUser': _maxGroupsPerUser,
        'allowPublicGroups': _allowPublicGroups,
      },
    };
  }
}