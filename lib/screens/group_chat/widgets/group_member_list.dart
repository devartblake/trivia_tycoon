import 'package:flutter/material.dart';
import '../../../core/services/social/group_chat_service.dart';

class GroupMemberList extends StatelessWidget {
  final GroupChat group;
  final String currentUserId;
  final Function(GroupMember)? onMemberTap;
  final Function(GroupMember)? onKickMember;
  final Function(GroupMember, GroupRole)? onChangeRole;

  const GroupMemberList({
    Key? key,
    required this.group,
    required this.currentUserId,
    this.onMemberTap,
    this.onKickMember,
    this.onChangeRole,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentMember = group.getMember(currentUserId);
    final canManage = currentMember?.role.canManageMembers ?? false;

    // Group members by role
    final owners = group.members.where((m) => m.role == GroupRole.owner).toList();
    final admins = group.members.where((m) => m.role == GroupRole.admin).toList();
    final moderators = group.members.where((m) => m.role == GroupRole.moderator).toList();
    final members = group.members.where((m) => m.role == GroupRole.member).toList();
    final spectators = group.members.where((m) => m.role == GroupRole.spectator).toList();

    return ListView(
      children: [
        if (owners.isNotEmpty) ...[
          _buildRoleHeader(context, 'Owner', owners.length),
          ...owners.map((m) => _buildMemberTile(context, m, canManage)),
        ],
        if (admins.isNotEmpty) ...[
          _buildRoleHeader(context, 'Admins', admins.length),
          ...admins.map((m) => _buildMemberTile(context, m, canManage)),
        ],
        if (moderators.isNotEmpty) ...[
          _buildRoleHeader(context, 'Moderators', moderators.length),
          ...moderators.map((m) => _buildMemberTile(context, m, canManage)),
        ],
        if (members.isNotEmpty) ...[
          _buildRoleHeader(context, 'Members', members.length),
          ...members.map((m) => _buildMemberTile(context, m, canManage)),
        ],
        if (spectators.isNotEmpty) ...[
          _buildRoleHeader(context, 'Spectators', spectators.length),
          ...spectators.map((m) => _buildMemberTile(context, m, canManage)),
        ],
      ],
    );
  }

  Widget _buildRoleHeader(BuildContext context, String role, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      child: Text(
        '$role ($count)',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildMemberTile(BuildContext context, GroupMember member, bool canManage) {
    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Theme.of(context).colorScheme.primary,
            backgroundImage: member.avatar != null
                ? NetworkImage(member.avatar!)
                : null,
            child: member.avatar == null
                ? Text(
              member.displayName[0].toUpperCase(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            )
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: member.isOnline ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              member.displayName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (member.role == GroupRole.owner)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, size: 12, color: Colors.amber.shade700),
                  const SizedBox(width: 2),
                  Text(
                    'Owner',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade700,
                    ),
                  ),
                ],
              ),
            ),
          if (member.role == GroupRole.admin)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield, size: 12, color: Colors.blue.shade700),
                  const SizedBox(width: 2),
                  Text(
                    'Admin',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      subtitle: Text(
        member.isOnline
            ? 'Online'
            : member.lastSeen != null
            ? 'Last seen ${_formatLastSeen(member.lastSeen!)}'
            : 'Offline',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: member.isOnline
              ? Colors.green.shade700
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: canManage && member.userId != currentUserId && member.role != GroupRole.owner
          ? PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: (value) => _handleMemberAction(context, value, member),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'view',
            child: ListTile(
              leading: Icon(Icons.person),
              title: Text('View Profile'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          if (member.role != GroupRole.admin)
            const PopupMenuItem(
              value: 'promote',
              child: ListTile(
                leading: Icon(Icons.arrow_upward),
                title: Text('Promote'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          if (member.role == GroupRole.admin || member.role == GroupRole.moderator)
            const PopupMenuItem(
              value: 'demote',
              child: ListTile(
                leading: Icon(Icons.arrow_downward),
                title: Text('Demote'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'kick',
            child: ListTile(
              leading: Icon(Icons.person_remove, color: Colors.red),
              title: Text('Kick', style: TextStyle(color: Colors.red)),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      )
          : null,
      onTap: () => onMemberTap?.call(member),
    );
  }

  void _handleMemberAction(BuildContext context, String action, GroupMember member) {
    switch (action) {
      case 'view':
        onMemberTap?.call(member);
        break;
      case 'promote':
        final newRole = member.role == GroupRole.member
            ? GroupRole.moderator
            : GroupRole.admin;
        onChangeRole?.call(member, newRole);
        break;
      case 'demote':
        final newRole = member.role == GroupRole.admin
            ? GroupRole.moderator
            : GroupRole.member;
        onChangeRole?.call(member, newRole);
        break;
      case 'kick':
        _showKickConfirmation(context, member);
        break;
    }
  }

  void _showKickConfirmation(BuildContext context, GroupMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kick Member'),
        content: Text('Are you sure you want to kick ${member.displayName} from this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              onKickMember?.call(member);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Kick'),
          ),
        ],
      ),
    );
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${lastSeen.day}/${lastSeen.month}';
    }
  }
}
