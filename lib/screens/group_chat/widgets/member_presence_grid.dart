import 'package:flutter/material.dart';

import '../../../core/services/social/group_chat_service.dart';

class MemberPresenceGrid extends StatelessWidget {
  final GroupChat group;
  final bool compact;
  final ScrollController? scrollController;
  final Function(GroupMember)? onMemberTap;

  const MemberPresenceGrid({
    Key? key,
    required this.group,
    this.compact = false,
    this.scrollController,
    this.onMemberTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildHorizontalList(context);
    }
    return _buildGridView(context);
  }

  Widget _buildHorizontalList(BuildContext context) {
    // Show online members first
    final sortedMembers = List<GroupMember>.from(group.members)
      ..sort((a, b) {
        if (a.isOnline && !b.isOnline) return -1;
        if (!a.isOnline && b.isOnline) return 1;
        return a.displayName.compareTo(b.displayName);
      });

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: sortedMembers.length,
      itemBuilder: (context, index) {
        return _buildMemberCard(context, sortedMembers[index], compact: true);
      },
    );
  }

  Widget _buildGridView(BuildContext context) {
    final sortedMembers = List<GroupMember>.from(group.members)
      ..sort((a, b) {
        if (a.isOnline && !b.isOnline) return -1;
        if (!a.isOnline && b.isOnline) return 1;
        return a.displayName.compareTo(b.displayName);
      });

    return GridView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: sortedMembers.length,
      itemBuilder: (context, index) {
        return _buildMemberCard(context, sortedMembers[index]);
      },
    );
  }

  Widget _buildMemberCard(BuildContext context, GroupMember member,
      {bool compact = false}) {
    return GestureDetector(
      onTap: () => onMemberTap?.call(member),
      child: Container(
        margin: compact ? const EdgeInsets.only(right: 12) : EdgeInsets.zero,
        width: compact ? 80 : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: compact ? 24 : 32,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  backgroundImage: member.avatar != null
                      ? NetworkImage(member.avatar!)
                      : null,
                  child: member.avatar == null
                      ? Text(
                          member.displayName[0].toUpperCase(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: compact ? 16 : 20,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: compact ? 12 : 16,
                    height: compact ? 12 : 16,
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
                if (member.role == GroupRole.owner ||
                    member.role == GroupRole.admin)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: member.role == GroupRole.owner
                            ? Colors.amber
                            : Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        member.role == GroupRole.owner
                            ? Icons.star
                            : Icons.shield,
                        size: compact ? 8 : 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              member.displayName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            if (!compact) ...[
              const SizedBox(height: 2),
              Text(
                member.role.displayName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
