import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/services/social/group_chat_service.dart';

// Helper to create a public group and return it (auto-assigns unique ID)
Future<GroupChat> _createPublicGroup(
  GroupChatService svc, {
  String suffix = '',
  String ownerName = 'Owner',
}) async {
  final group = await svc.createGroup(
    name: 'TestGroup_$suffix',
    type: GroupType.publicGroup,
    ownerId: 'owner_$suffix',
    ownerDisplayName: ownerName,
  );
  return group!;
}

// Helper to create a game session group
Future<GroupChat> _createGameSession(
  GroupChatService svc, {
  String suffix = '',
}) async {
  final group = await svc.createGroup(
    name: 'GameSession_$suffix',
    type: GroupType.gameSession,
    ownerId: 'owner_$suffix',
    ownerDisplayName: 'Owner',
  );
  return group!;
}

void main() {
  late GroupChatService svc;

  setUpAll(() {
    svc = GroupChatService();
    svc.initialize();
  });

  tearDownAll(() {
    svc.dispose();
  });

  // -------------------------------------------------------------------------
  // GroupRole enum
  // -------------------------------------------------------------------------

  group('GroupRole enum', () {
    test('has 5 values', () {
      expect(GroupRole.values.length, 5);
    });

    test('canManageMembers true for owner', () {
      expect(GroupRole.owner.canManageMembers, isTrue);
    });

    test('canManageMembers true for admin', () {
      expect(GroupRole.admin.canManageMembers, isTrue);
    });

    test('canManageMembers false for moderator', () {
      expect(GroupRole.moderator.canManageMembers, isFalse);
    });

    test('canManageMembers false for member', () {
      expect(GroupRole.member.canManageMembers, isFalse);
    });

    test('canManageMembers false for spectator', () {
      expect(GroupRole.spectator.canManageMembers, isFalse);
    });

    test('canModerateChat true for owner/admin/moderator', () {
      expect(GroupRole.owner.canModerateChat, isTrue);
      expect(GroupRole.admin.canModerateChat, isTrue);
      expect(GroupRole.moderator.canModerateChat, isTrue);
    });

    test('canModerateChat false for member and spectator', () {
      expect(GroupRole.member.canModerateChat, isFalse);
      expect(GroupRole.spectator.canModerateChat, isFalse);
    });

    test('canSendMessages true for all except spectator', () {
      expect(GroupRole.owner.canSendMessages, isTrue);
      expect(GroupRole.admin.canSendMessages, isTrue);
      expect(GroupRole.moderator.canSendMessages, isTrue);
      expect(GroupRole.member.canSendMessages, isTrue);
    });

    test('canSendMessages false for spectator', () {
      expect(GroupRole.spectator.canSendMessages, isFalse);
    });

    test('all roles have non-empty displayName', () {
      for (final role in GroupRole.values) {
        expect(role.displayName.isNotEmpty, isTrue);
      }
    });
  });

  // -------------------------------------------------------------------------
  // GroupType enum
  // -------------------------------------------------------------------------

  group('GroupType enum', () {
    test('has 4 values', () {
      expect(GroupType.values.length, 4);
    });

    test('all types have non-empty displayName', () {
      for (final type in GroupType.values) {
        expect(type.displayName.isNotEmpty, isTrue);
      }
    });

    test('publicGroup displayName', () {
      expect(GroupType.publicGroup.displayName, 'Public Group');
    });

    test('gameSession displayName', () {
      expect(GroupType.gameSession.displayName, 'Game Session');
    });
  });

  // -------------------------------------------------------------------------
  // GroupMember class
  // -------------------------------------------------------------------------

  group('GroupMember', () {
    final member = GroupMember(
      userId: 'u1',
      displayName: 'Alice',
      role: GroupRole.member,
      joinedAt: DateTime(2026, 1, 1),
    );

    test('userId stored correctly', () {
      expect(member.userId, 'u1');
    });

    test('displayName stored correctly', () {
      expect(member.displayName, 'Alice');
    });

    test('role stored correctly', () {
      expect(member.role, GroupRole.member);
    });

    test('isOnline defaults to false', () {
      expect(member.isOnline, isFalse);
    });

    test('copyWith updates role', () {
      final updated = member.copyWith(role: GroupRole.admin);
      expect(updated.role, GroupRole.admin);
      expect(updated.userId, 'u1');
    });

    test('copyWith updates isOnline', () {
      final updated = member.copyWith(isOnline: true);
      expect(updated.isOnline, isTrue);
      expect(updated.displayName, 'Alice');
    });

    test('toJson contains userId', () {
      final json = member.toJson();
      expect(json['userId'], 'u1');
    });

    test('toJson contains role name', () {
      final json = member.toJson();
      expect(json['role'], 'member');
    });

    test('fromJson round-trip', () {
      final json = member.toJson();
      final restored = GroupMember.fromJson(json);
      expect(restored.userId, member.userId);
      expect(restored.role, member.role);
      expect(restored.isOnline, member.isOnline);
    });
  });

  // -------------------------------------------------------------------------
  // GroupChat class
  // -------------------------------------------------------------------------

  group('GroupChat class', () {
    final now = DateTime(2026, 1, 1);
    final owner = GroupMember(
      userId: 'o1',
      displayName: 'Owner',
      role: GroupRole.owner,
      joinedAt: now,
    );
    final member = GroupMember(
      userId: 'm1',
      displayName: 'Member',
      role: GroupRole.member,
      joinedAt: now,
      isOnline: true,
    );
    final chat = GroupChat(
      id: 'g1',
      name: 'Test Chat',
      type: GroupType.publicGroup,
      ownerId: 'o1',
      members: [owner, member],
      createdAt: now,
      lastActivity: now,
    );

    test('memberCount = 2', () {
      expect(chat.memberCount, 2);
    });

    test('onlineMemberCount = 1 (only member is online)', () {
      expect(chat.onlineMemberCount, 1);
    });

    test('onlineMembers list has 1 entry', () {
      expect(chat.onlineMembers.length, 1);
    });

    test('admins list contains owner', () {
      expect(chat.admins.map((m) => m.userId), contains('o1'));
    });

    test('getMember returns correct member', () {
      expect(chat.getMember('m1')?.displayName, 'Member');
    });

    test('getMember returns null for unknown userId', () {
      expect(chat.getMember('unknown'), isNull);
    });

    test('canUserPerformAction true for owner acting as owner', () {
      expect(chat.canUserPerformAction('o1', GroupRole.owner), isTrue);
    });

    test('canUserPerformAction true for owner acting as member', () {
      expect(chat.canUserPerformAction('o1', GroupRole.member), isTrue);
    });

    test('canUserPerformAction false for member acting as owner', () {
      expect(chat.canUserPerformAction('m1', GroupRole.owner), isFalse);
    });

    test('canUserPerformAction false for unknown user', () {
      expect(chat.canUserPerformAction('nobody', GroupRole.member), isFalse);
    });

    test('toJson contains id', () {
      expect(chat.toJson()['id'], 'g1');
    });

    test('fromJson round-trip', () {
      final json = chat.toJson();
      final restored = GroupChat.fromJson(json);
      expect(restored.id, 'g1');
      expect(restored.memberCount, 2);
    });

    test('copyWith updates name', () {
      final updated = chat.copyWith(name: 'New Name');
      expect(updated.name, 'New Name');
      expect(updated.id, 'g1');
    });
  });

  // -------------------------------------------------------------------------
  // createGroup
  // -------------------------------------------------------------------------

  group('createGroup', () {
    test('returns non-null GroupChat', () async {
      final group = await svc.createGroup(
        name: 'TestCreate1',
        type: GroupType.publicGroup,
        ownerId: 'owner_c1',
        ownerDisplayName: 'Tester',
      );
      expect(group, isNotNull);
      await svc.deleteGroup(group!.id, 'owner_c1');
    });

    test('group appears in allGroups', () async {
      final group = await svc.createGroup(
        name: 'TestCreate2',
        type: GroupType.publicGroup,
        ownerId: 'owner_c2',
        ownerDisplayName: 'Tester',
      );
      expect(svc.getGroup(group!.id), isNotNull);
      await svc.deleteGroup(group.id, 'owner_c2');
    });

    test('owner is added as member with owner role', () async {
      final group = await svc.createGroup(
        name: 'TestCreate3',
        type: GroupType.publicGroup,
        ownerId: 'owner_c3',
        ownerDisplayName: 'OwnerUser',
      );
      expect(group!.getMember('owner_c3')?.role, GroupRole.owner);
      await svc.deleteGroup(group.id, 'owner_c3');
    });

    test('returns null for empty name', () async {
      final group = await svc.createGroup(
        name: '',
        type: GroupType.publicGroup,
        ownerId: 'owner_c4',
        ownerDisplayName: 'Tester',
      );
      expect(group, isNull);
    });

    test('initial members added on create', () async {
      final group = await svc.createGroup(
        name: 'TestCreate5',
        type: GroupType.publicGroup,
        ownerId: 'owner_c5',
        ownerDisplayName: 'Tester',
        initialMemberIds: ['extra_u1', 'extra_u2'],
      );
      expect(group!.memberCount, 3); // owner + 2 initial
      await svc.deleteGroup(group.id, 'owner_c5');
    });
  });

  // -------------------------------------------------------------------------
  // joinGroup
  // -------------------------------------------------------------------------

  group('joinGroup', () {
    test('true when non-member joins public group', () async {
      final group = await _createPublicGroup(svc, suffix: 'join1');
      final result = await svc.joinGroup(group.id, 'joiner1', 'Joiner One');
      expect(result, isTrue);
      await svc.deleteGroup(group.id, 'owner_join1');
    });

    test('false when already a member', () async {
      final group = await _createPublicGroup(svc, suffix: 'join2');
      await svc.joinGroup(group.id, 'joiner2', 'Joiner');
      final result = await svc.joinGroup(group.id, 'joiner2', 'Joiner');
      expect(result, isFalse);
      await svc.deleteGroup(group.id, 'owner_join2');
    });

    test('false for private group without invitation', () async {
      final group = await svc.createGroup(
        name: 'PrivateGroup_join3',
        type: GroupType.privateGroup,
        ownerId: 'owner_join3',
        ownerDisplayName: 'Owner',
      );
      final result = await svc.joinGroup(group!.id, 'outsider', 'Outsider');
      expect(result, isFalse);
      await svc.deleteGroup(group.id, 'owner_join3');
    });

    test('false for unknown group ID', () async {
      final result = await svc.joinGroup('nonexistent_id', 'user1', 'User');
      expect(result, isFalse);
    });

    test('member count increments after join', () async {
      final group = await _createPublicGroup(svc, suffix: 'join5');
      final before = svc.getGroup(group.id)!.memberCount;
      await svc.joinGroup(group.id, 'new_joiner5', 'Joiner');
      final after = svc.getGroup(group.id)!.memberCount;
      expect(after, before + 1);
      await svc.deleteGroup(group.id, 'owner_join5');
    });
  });

  // -------------------------------------------------------------------------
  // leaveGroup
  // -------------------------------------------------------------------------

  group('leaveGroup', () {
    test('true when regular member leaves', () async {
      final group = await _createPublicGroup(svc, suffix: 'leave1');
      await svc.joinGroup(group.id, 'leaver1', 'Leaver');
      final result = await svc.leaveGroup(group.id, 'leaver1');
      expect(result, isTrue);
      await svc.deleteGroup(group.id, 'owner_leave1');
    });

    test('false when user not in group', () async {
      final group = await _createPublicGroup(svc, suffix: 'leave2');
      final result = await svc.leaveGroup(group.id, 'not_a_member');
      expect(result, isFalse);
      await svc.deleteGroup(group.id, 'owner_leave2');
    });

    test('false for unknown group', () async {
      final result = await svc.leaveGroup('bad_group_id', 'user1');
      expect(result, isFalse);
    });

    test('member count decrements after leave', () async {
      final group = await _createPublicGroup(svc, suffix: 'leave4');
      await svc.joinGroup(group.id, 'leaver4', 'Leaver');
      final before = svc.getGroup(group.id)!.memberCount;
      await svc.leaveGroup(group.id, 'leaver4');
      final after = svc.getGroup(group.id)!.memberCount;
      expect(after, before - 1);
      await svc.deleteGroup(group.id, 'owner_leave4');
    });
  });

  // -------------------------------------------------------------------------
  // deleteGroup
  // -------------------------------------------------------------------------

  group('deleteGroup', () {
    test('true when owner deletes group', () async {
      final group = await _createPublicGroup(svc, suffix: 'del1');
      final result = await svc.deleteGroup(group.id, 'owner_del1');
      expect(result, isTrue);
    });

    test('group removed from allGroups after delete', () async {
      final group = await _createPublicGroup(svc, suffix: 'del2');
      await svc.deleteGroup(group.id, 'owner_del2');
      expect(svc.getGroup(group.id), isNull);
    });

    test('false when non-owner tries to delete', () async {
      final group = await _createPublicGroup(svc, suffix: 'del3');
      await svc.joinGroup(group.id, 'non_owner_del3', 'User');
      final result = await svc.deleteGroup(group.id, 'non_owner_del3');
      expect(result, isFalse);
      await svc.deleteGroup(group.id, 'owner_del3');
    });

    test('false for unknown group', () async {
      final result = await svc.deleteGroup('bad_id', 'anyone');
      expect(result, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // updateMemberRole
  // -------------------------------------------------------------------------

  group('updateMemberRole', () {
    test('true when owner promotes member to admin', () async {
      final group = await _createPublicGroup(svc, suffix: 'role1');
      await svc.joinGroup(group.id, 'member_role1', 'Member');
      final result = await svc.updateMemberRole(
        group.id, 'member_role1', GroupRole.admin, 'owner_role1',
      );
      expect(result, isTrue);
      await svc.deleteGroup(group.id, 'owner_role1');
    });

    test('false when non-admin tries to update role', () async {
      final group = await _createPublicGroup(svc, suffix: 'role2');
      await svc.joinGroup(group.id, 'memberA_role2', 'MemberA');
      await svc.joinGroup(group.id, 'memberB_role2', 'MemberB');
      final result = await svc.updateMemberRole(
        group.id, 'memberB_role2', GroupRole.admin, 'memberA_role2',
      );
      expect(result, isFalse);
      await svc.deleteGroup(group.id, 'owner_role2');
    });

    test('false when targeting owner role', () async {
      final group = await _createPublicGroup(svc, suffix: 'role3');
      await svc.joinGroup(group.id, 'member_role3', 'Member');
      final result = await svc.updateMemberRole(
        group.id, 'owner_role3', GroupRole.member, 'owner_role3',
      );
      expect(result, isFalse);
      await svc.deleteGroup(group.id, 'owner_role3');
    });

    test('role updated in group after success', () async {
      final group = await _createPublicGroup(svc, suffix: 'role4');
      await svc.joinGroup(group.id, 'member_role4', 'Member');
      await svc.updateMemberRole(
        group.id, 'member_role4', GroupRole.moderator, 'owner_role4',
      );
      final updated = svc.getGroup(group.id)!;
      expect(updated.getMember('member_role4')!.role, GroupRole.moderator);
      await svc.deleteGroup(group.id, 'owner_role4');
    });
  });

  // -------------------------------------------------------------------------
  // kickMember
  // -------------------------------------------------------------------------

  group('kickMember', () {
    test('true when admin kicks member', () async {
      final group = await _createPublicGroup(svc, suffix: 'kick1');
      await svc.joinGroup(group.id, 'kickee1', 'Kickee');
      final result = await svc.kickMember(group.id, 'kickee1', 'owner_kick1');
      expect(result, isTrue);
      await svc.deleteGroup(group.id, 'owner_kick1');
    });

    test('false when trying to kick owner', () async {
      final group = await _createPublicGroup(svc, suffix: 'kick2');
      await svc.joinGroup(group.id, 'admin_kick2', 'Admin');
      await svc.updateMemberRole(
          group.id, 'admin_kick2', GroupRole.admin, 'owner_kick2');
      final result =
          await svc.kickMember(group.id, 'owner_kick2', 'admin_kick2');
      expect(result, isFalse);
      await svc.deleteGroup(group.id, 'owner_kick2');
    });

    test('member removed from group after kick', () async {
      final group = await _createPublicGroup(svc, suffix: 'kick3');
      await svc.joinGroup(group.id, 'kickee3', 'Kickee');
      await svc.kickMember(group.id, 'kickee3', 'owner_kick3');
      expect(svc.getGroup(group.id)!.getMember('kickee3'), isNull);
      await svc.deleteGroup(group.id, 'owner_kick3');
    });
  });

  // -------------------------------------------------------------------------
  // updateMemberPresence
  // -------------------------------------------------------------------------

  group('updateMemberPresence', () {
    test('isOnline updated to true', () async {
      final group = await _createPublicGroup(svc, suffix: 'pres1');
      await svc.joinGroup(group.id, 'presUser1', 'User');
      svc.updateMemberPresence('presUser1', true);
      final member = svc.getGroup(group.id)!.getMember('presUser1');
      expect(member!.isOnline, isTrue);
      await svc.deleteGroup(group.id, 'owner_pres1');
    });

    test('isOnline updated to false', () async {
      final group = await _createPublicGroup(svc, suffix: 'pres2');
      await svc.joinGroup(group.id, 'presUser2', 'User');
      svc.updateMemberPresence('presUser2', true);
      svc.updateMemberPresence('presUser2', false);
      final member = svc.getGroup(group.id)!.getMember('presUser2');
      expect(member!.isOnline, isFalse);
      await svc.deleteGroup(group.id, 'owner_pres2');
    });

    test('no-op for unknown user (no error)', () {
      svc.updateMemberPresence('totally_unknown_user', true);
    });
  });

  // -------------------------------------------------------------------------
  // getGroup
  // -------------------------------------------------------------------------

  group('getGroup', () {
    test('null for unknown ID', () {
      expect(svc.getGroup('nonexistent_group_xyz'), isNull);
    });

    test('returns group after creation', () async {
      final group = await _createPublicGroup(svc, suffix: 'get1');
      expect(svc.getGroup(group.id), isNotNull);
      await svc.deleteGroup(group.id, 'owner_get1');
    });
  });

  // -------------------------------------------------------------------------
  // getUserGroups
  // -------------------------------------------------------------------------

  group('getUserGroups', () {
    test('empty for user not in any group', () {
      final groups = svc.getUserGroups('user_not_in_any_group_xyz');
      expect(groups, isEmpty);
    });

    test('contains group after creation (owner is member)', () async {
      final group = await _createPublicGroup(svc, suffix: 'ug1');
      final groups = svc.getUserGroups('owner_ug1');
      expect(groups.any((g) => g.id == group.id), isTrue);
      await svc.deleteGroup(group.id, 'owner_ug1');
    });

    test('contains group after joining', () async {
      final group = await _createPublicGroup(svc, suffix: 'ug2');
      await svc.joinGroup(group.id, 'joiner_ug2', 'Joiner');
      final groups = svc.getUserGroups('joiner_ug2');
      expect(groups.any((g) => g.id == group.id), isTrue);
      await svc.deleteGroup(group.id, 'owner_ug2');
    });

    test('does not contain group after leaving', () async {
      final group = await _createPublicGroup(svc, suffix: 'ug3');
      await svc.joinGroup(group.id, 'leaver_ug3', 'Leaver');
      await svc.leaveGroup(group.id, 'leaver_ug3');
      final groups = svc.getUserGroups('leaver_ug3');
      expect(groups.any((g) => g.id == group.id), isFalse);
      await svc.deleteGroup(group.id, 'owner_ug3');
    });
  });

  // -------------------------------------------------------------------------
  // getPublicGroups
  // -------------------------------------------------------------------------

  group('getPublicGroups', () {
    test('contains newly created public group', () async {
      final group = await _createPublicGroup(svc, suffix: 'pg1');
      final public = svc.getPublicGroups();
      expect(public.any((g) => g.id == group.id), isTrue);
      await svc.deleteGroup(group.id, 'owner_pg1');
    });

    test('does not contain private groups', () async {
      final privateGroup = await svc.createGroup(
        name: 'PrivateGroup_pg2',
        type: GroupType.privateGroup,
        ownerId: 'owner_pg2',
        ownerDisplayName: 'Owner',
      );
      final public = svc.getPublicGroups();
      expect(public.any((g) => g.id == privateGroup!.id), isFalse);
      await svc.deleteGroup(privateGroup!.id, 'owner_pg2');
    });
  });

  // -------------------------------------------------------------------------
  // getActiveGameSessions
  // -------------------------------------------------------------------------

  group('getActiveGameSessions', () {
    test('contains created game session with online member', () async {
      final group = await _createGameSession(svc, suffix: 'gs1');
      // Owner is online by default (isOnline=true when created)
      final sessions = svc.getActiveGameSessions();
      expect(sessions.any((g) => g.id == group.id), isTrue);
      await svc.deleteGroup(group.id, 'owner_gs1');
    });
  });

  // -------------------------------------------------------------------------
  // searchGroups
  // -------------------------------------------------------------------------

  group('searchGroups', () {
    test('finds group by name substring', () async {
      final group = await svc.createGroup(
        name: 'UniqueSearchTarget_xyz',
        type: GroupType.publicGroup,
        ownerId: 'owner_search1',
        ownerDisplayName: 'Owner',
      );
      final results = svc.searchGroups('UniqueSearchTarget');
      expect(results.any((g) => g.id == group!.id), isTrue);
      await svc.deleteGroup(group!.id, 'owner_search1');
    });

    test('empty list for non-matching query', () {
      final results = svc.searchGroups('zzz_no_such_group_xyz');
      expect(results, isEmpty);
    });

    test('case-insensitive search', () async {
      final group = await svc.createGroup(
        name: 'MixedCaseGroupSearch',
        type: GroupType.publicGroup,
        ownerId: 'owner_search3',
        ownerDisplayName: 'Owner',
      );
      final results = svc.searchGroups('mixedcasegroupsearch');
      expect(results.any((g) => g.id == group!.id), isTrue);
      await svc.deleteGroup(group!.id, 'owner_search3');
    });
  });

  // -------------------------------------------------------------------------
  // updateGroupSettings
  // -------------------------------------------------------------------------

  group('updateGroupSettings', () {
    test('true when owner updates name', () async {
      final group = await _createPublicGroup(svc, suffix: 'settings1');
      final result = await svc.updateGroupSettings(
        groupId: group.id,
        name: 'Updated Name',
        requesterId: 'owner_settings1',
      );
      expect(result, isTrue);
      expect(svc.getGroup(group.id)!.name, 'Updated Name');
      await svc.deleteGroup(group.id, 'owner_settings1');
    });

    test('false when non-member tries to update', () async {
      final group = await _createPublicGroup(svc, suffix: 'settings2');
      final result = await svc.updateGroupSettings(
        groupId: group.id,
        name: 'Hacked Name',
        requesterId: 'nobody_settings2',
      );
      expect(result, isFalse);
      await svc.deleteGroup(group.id, 'owner_settings2');
    });
  });

  // -------------------------------------------------------------------------
  // inviteToGroup
  // -------------------------------------------------------------------------

  group('inviteToGroup', () {
    test('true when owner invites (placeholder implementation)', () async {
      final group = await _createPublicGroup(svc, suffix: 'invite1');
      final result = await svc.inviteToGroup(
          group.id, 'invitee1', 'owner_invite1');
      expect(result, isTrue);
      await svc.deleteGroup(group.id, 'owner_invite1');
    });

    test('false when non-member tries to invite', () async {
      final group = await _createPublicGroup(svc, suffix: 'invite2');
      final result = await svc.inviteToGroup(
          group.id, 'invitee2', 'nobody_invite2');
      expect(result, isFalse);
      await svc.deleteGroup(group.id, 'owner_invite2');
    });
  });

  // -------------------------------------------------------------------------
  // watchGroup stream
  // -------------------------------------------------------------------------

  group('watchGroup stream', () {
    test('emits event after joinGroup', () async {
      final group = await _createPublicGroup(svc, suffix: 'stream1');
      final stream = svc.watchGroup(group.id);
      final future = stream.first;
      await svc.joinGroup(group.id, 'stream_joiner1', 'Joiner');
      final emitted = await future.timeout(const Duration(seconds: 2));
      expect(emitted.id, group.id);
      await svc.deleteGroup(group.id, 'owner_stream1');
    });
  });

  // -------------------------------------------------------------------------
  // getGroupAnalytics
  // -------------------------------------------------------------------------

  group('getGroupAnalytics', () {
    test('returns empty map for unknown group', () {
      expect(svc.getGroupAnalytics('bad_id'), isEmpty);
    });

    test('returns map with totalMembers key', () async {
      final group = await _createPublicGroup(svc, suffix: 'analytics1');
      final analytics = svc.getGroupAnalytics(group.id);
      expect(analytics.containsKey('totalMembers'), isTrue);
      await svc.deleteGroup(group.id, 'owner_analytics1');
    });

    test('totalMembers reflects current count', () async {
      final group = await _createPublicGroup(svc, suffix: 'analytics2');
      await svc.joinGroup(group.id, 'user_analytics2', 'User');
      final analytics = svc.getGroupAnalytics(group.id);
      expect(analytics['totalMembers'], 2);
      await svc.deleteGroup(group.id, 'owner_analytics2');
    });

    test('contains onlineMembers key', () async {
      final group = await _createPublicGroup(svc, suffix: 'analytics3');
      final analytics = svc.getGroupAnalytics(group.id);
      expect(analytics.containsKey('onlineMembers'), isTrue);
      await svc.deleteGroup(group.id, 'owner_analytics3');
    });

    test('contains roleDistribution key', () async {
      final group = await _createPublicGroup(svc, suffix: 'analytics4');
      final analytics = svc.getGroupAnalytics(group.id);
      expect(analytics.containsKey('roleDistribution'), isTrue);
      await svc.deleteGroup(group.id, 'owner_analytics4');
    });
  });

  // -------------------------------------------------------------------------
  // getServiceAnalytics
  // -------------------------------------------------------------------------

  group('getServiceAnalytics', () {
    test('returns map with totalGroups key', () {
      final analytics = svc.getServiceAnalytics();
      expect(analytics.containsKey('totalGroups'), isTrue);
    });

    test('returns map with activeGroups key', () {
      final analytics = svc.getServiceAnalytics();
      expect(analytics.containsKey('activeGroups'), isTrue);
    });

    test('returns map with totalMembers key', () {
      final analytics = svc.getServiceAnalytics();
      expect(analytics.containsKey('totalMembers'), isTrue);
    });

    test('totalGroups increases after createGroup', () async {
      final before = svc.getServiceAnalytics()['totalGroups'] as int;
      final group = await _createPublicGroup(svc, suffix: 'svc_analytics');
      final after = svc.getServiceAnalytics()['totalGroups'] as int;
      expect(after, before + 1);
      await svc.deleteGroup(group.id, 'owner_svc_analytics');
    });
  });
}
