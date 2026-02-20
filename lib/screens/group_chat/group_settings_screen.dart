import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/social/group_chat_service.dart';
import 'widgets/group_member_list.dart';

class GroupSettingsScreen extends StatefulWidget {
  final String groupId;
  final String currentUserId;

  const GroupSettingsScreen({
    Key? key,
    required this.groupId,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends State<GroupSettingsScreen> with SingleTickerProviderStateMixin {
  final GroupChatService _groupService = GroupChatService();
  late TabController _tabController;

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadGroupInfo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadGroupInfo() {
    final group = _groupService.getGroup(widget.groupId);
    if (group != null) {
      _nameController.text = group.name;
      _descriptionController.text = group.description ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GroupChat>(
      stream: _groupService.watchGroup(widget.groupId),
      builder: (context, snapshot) {
        final group = snapshot.data ?? _groupService.getGroup(widget.groupId);

        if (group == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Group Not Found')),
            body: const Center(child: Text('This group no longer exists.')),
          );
        }

        final member = group.getMember(widget.currentUserId);
        final canManage = member?.role.canManageMembers ?? false;

        return Scaffold(
          appBar: _buildAppBar(context, group, canManage),
          body: Column(
            children: [
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildGeneralTab(context, group, canManage),
                    _buildMembersTab(context, group, canManage),
                    _buildPrivacyTab(context, group, canManage),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, GroupChat group, bool canManage) {
    return AppBar(
      title: Text(_isEditing ? 'Edit Group' : 'Group Settings'),
      actions: [
        if (canManage && !_isEditing)
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => setState(() => _isEditing = true),
            tooltip: 'Edit Group',
          ),
        if (_isEditing) ...[
          TextButton(
            onPressed: _isSaving ? null : _cancelEditing,
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: _isSaving ? null : () => _saveChanges(group),
            child: _isSaving
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Text('Save'),
          ),
        ],
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(icon: Icon(Icons.settings), text: 'General'),
          Tab(icon: Icon(Icons.people), text: 'Members'),
          Tab(icon: Icon(Icons.privacy_tip), text: 'Privacy'),
        ],
      ),
    );
  }

  Widget _buildGeneralTab(BuildContext context, GroupChat group, bool canManage) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildGroupAvatar(context, group, canManage),
        const SizedBox(height: 24),
        _buildInfoSection(context, group, canManage),
        const SizedBox(height: 24),
        _buildStatsSection(context, group),
        const SizedBox(height: 24),
        _buildActionsSection(context, group),
      ],
    );
  }

  Widget _buildGroupAvatar(BuildContext context, GroupChat group, bool canManage) {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primaryContainer,
              image: group.avatar != null
                  ? DecorationImage(
                image: NetworkImage(group.avatar!),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            child: group.avatar == null
                ? Icon(
              Icons.group,
              size: 60,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            )
                : null,
          ),
          if (canManage && _isEditing)
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _changeAvatar,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    size: 20,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, GroupChat group, bool canManage) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Group Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              enabled: _isEditing,
              decoration: InputDecoration(
                labelText: 'Group Name',
                prefixIcon: const Icon(Icons.label),
                border: const OutlineInputBorder(),
                filled: !_isEditing,
              ),
              maxLength: 50,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              enabled: _isEditing,
              decoration: InputDecoration(
                labelText: 'Description',
                prefixIcon: const Icon(Icons.description),
                border: const OutlineInputBorder(),
                filled: !_isEditing,
              ),
              maxLines: 3,
              maxLength: 200,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(
                _getGroupTypeIcon(group.type),
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Group Type'),
              subtitle: Text(group.type.displayName),
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: Icon(
                Icons.calendar_today,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Created'),
              subtitle: Text(_formatDate(group.createdAt)),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, GroupChat group) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Group Statistics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatItem(
                  context,
                  Icons.people,
                  '${group.memberCount}',
                  'Members',
                ),
                _buildStatItem(
                  context,
                  Icons.circle,
                  '${group.onlineMemberCount}',
                  'Online',
                  color: Colors.green,
                ),
                _buildStatItem(
                  context,
                  Icons.shield,
                  '${group.admins.length}',
                  'Admins',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      BuildContext context,
      IconData icon,
      String value,
      String label, {
        Color? color,
      }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color ?? Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(BuildContext context, GroupChat group) {
    final member = group.getMember(widget.currentUserId);
    final isOwner = member?.role == GroupRole.owner;

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            trailing: Switch(
              value: true, // This would be from user settings
              onChanged: (value) {
                // Toggle notifications
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('Invite Link'),
            subtitle: const Text('Share this group with others'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showInviteLink(group),
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              Icons.exit_to_app,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Leave Group',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => _confirmLeaveGroup(context, group),
          ),
          if (isOwner) ...[
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.delete_forever,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Delete Group',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              subtitle: const Text('This action cannot be undone'),
              onTap: () => _confirmDeleteGroup(context, group),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMembersTab(BuildContext context, GroupChat group, bool canManage) {
    return GroupMemberList(
      group: group,
      currentUserId: widget.currentUserId,
      onMemberTap: (member) {
        // Show member profile
      },
      onKickMember: canManage ? (member) => _kickMember(group, member) : null,
      onChangeRole: canManage ? (member, newRole) => _changeRole(group, member, newRole) : null,
    );
  }

  Widget _buildPrivacyTab(BuildContext context, GroupChat group, bool canManage) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Allow Message Reactions'),
                subtitle: const Text('Members can react to messages'),
                value: true,
                onChanged: canManage ? (value) {} : null,
              ),
              SwitchListTile(
                title: const Text('Allow GIFs'),
                subtitle: const Text('Members can send GIF images'),
                value: true,
                onChanged: canManage ? (value) {} : null,
              ),
              SwitchListTile(
                title: const Text('Allow File Sharing'),
                subtitle: const Text('Members can share files'),
                value: true,
                onChanged: canManage ? (value) {} : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                title: const Text('Who Can Add Members'),
                subtitle: const Text('Admins and Moderators'),
                trailing: const Icon(Icons.chevron_right),
                enabled: canManage,
                onTap: canManage ? () {} : null,
              ),
              ListTile(
                title: const Text('Who Can Send Messages'),
                subtitle: const Text('All Members'),
                trailing: const Icon(Icons.chevron_right),
                enabled: canManage,
                onTap: canManage ? () {} : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _cancelEditing() {
    setState(() => _isEditing = false);
    _loadGroupInfo();
  }

  Future<void> _saveChanges(GroupChat group) async {
    setState(() => _isSaving = true);

    try {
      final success = await _groupService.updateGroupSettings(
        groupId: widget.groupId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        requesterId: widget.currentUserId,
      );

      if (success && mounted) {
        HapticFeedback.mediumImpact();
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group settings updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _changeAvatar() {
    // Implement avatar change
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                // Handle gallery selection
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                // Handle camera
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Remove Photo'),
              onTap: () {
                Navigator.pop(context);
                // Handle removal
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showInviteLink(GroupChat group) {
    final inviteLink = 'https://yourapp.com/invite/${group.id}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite Link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Share this link to invite people to ${group.name}'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                inviteLink,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: inviteLink));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link copied to clipboard')),
              );
              Navigator.pop(context);
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy Link'),
          ),
        ],
      ),
    );
  }

  void _confirmLeaveGroup(BuildContext context, GroupChat group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: Text('Are you sure you want to leave "${group.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _groupService.leaveGroup(
                widget.groupId,
                widget.currentUserId,
              );
              if (success && mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Left group successfully')),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteGroup(BuildContext context, GroupChat group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${group.name}"?'),
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone. All messages and data will be permanently deleted.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _groupService.deleteGroup(
                widget.groupId,
                widget.currentUserId,
              );
              if (success && mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Group deleted successfully')),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _kickMember(GroupChat group, GroupMember member) async {
    final success = await _groupService.kickMember(
      widget.groupId,
      member.userId,
      widget.currentUserId,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${member.displayName} has been removed')),
      );
    }
  }

  Future<void> _changeRole(GroupChat group, GroupMember member, GroupRole newRole) async {
    final success = await _groupService.updateMemberRole(
      widget.groupId,
      member.userId,
      newRole,
      widget.currentUserId,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${member.displayName} is now ${newRole.displayName}'),
        ),
      );
    }
  }

  IconData _getGroupTypeIcon(GroupType type) {
    switch (type) {
      case GroupType.privateGroup:
        return Icons.lock;
      case GroupType.publicGroup:
        return Icons.public;
      case GroupType.gameSession:
        return Icons.sports_esports;
      case GroupType.spectatorRoom:
        return Icons.visibility;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
