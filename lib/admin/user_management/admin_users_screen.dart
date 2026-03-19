import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/models/admin_user_model.dart';
import '../../game/providers/riverpod_providers.dart';
import '../../screens/widgets/custom_alert_dialog.dart';
import 'admin_user_helpers.dart';
import 'admin_users_mock_data.dart';
import 'widgets/admin_user_card.dart';
import 'widgets/admin_users_header.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  UserStatus? _filterStatus;
  UserRole? _filterRole;
  AgeGroup? _filterAgeGroup;
  String _sortBy = 'lastActive';
  List<AdminUserModel> _users = [];
  bool _isLoadingUsers = false;
  String? _usersError;

  @override
  void initState() {
    super.initState();
    _loadUsersFromBackend();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsersFromBackend() async {
    setState(() {
      _isLoadingUsers = true;
      _usersError = null;
    });

    try {
      final serviceManager = ref.read(serviceManagerProvider);
      final response = await serviceManager.apiService.get('/admin/users');
      final items = response['items'];
      if (items is List) {
        _users = items
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .map(AdminUserModel.fromJson)
            .toList();
      } else {
        _users = [];
      }
    } catch (e) {
      _usersError = 'Using local sample users (backend unavailable): $e';
      _users = getMockUsers();
    } finally {
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  List<AdminUserModel> _getFilteredUsers() {
    var users = _users;

    if (_searchQuery.isNotEmpty) {
      users = users.where((u) {
        return u.username.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            u.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            u.id.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    if (_filterStatus != null) {
      users = users.where((u) => u.status == _filterStatus).toList();
    }
    if (_filterRole != null) {
      users = users.where((u) => u.role == _filterRole).toList();
    }
    if (_filterAgeGroup != null) {
      users = users.where((u) => u.ageGroup == _filterAgeGroup).toList();
    }

    switch (_sortBy) {
      case 'lastActive':
        users.sort((a, b) => b.lastActive.compareTo(a.lastActive));
        break;
      case 'username':
        users.sort((a, b) => a.username.compareTo(b.username));
        break;
      case 'points':
        users.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
        break;
    }

    return users;
  }

  @override
  Widget build(BuildContext context) {
    final users = _getFilteredUsers();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          AdminUsersHeader(
            searchController: _searchController,
            searchQuery: _searchQuery,
            onSearchChanged: (value) {
              _searchController.text = value;
              setState(() => _searchQuery = value);
            },
          ),
          if (_isLoadingUsers) const LinearProgressIndicator(minHeight: 2),
          if (_usersError != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFFFF7ED),
              child: Text(
                _usersError!,
                style: const TextStyle(
                    color: Color(0xFF9A3412), fontSize: 12),
              ),
            ),
          _buildFilters(),
          Expanded(
            child: users.isEmpty
                ? _buildEmptyState()
                : _buildUsersList(users),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUserDialog,
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add User'),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Filter bar
  // ---------------------------------------------------------------------------

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Text(
              'Filters:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(width: 16),
            _buildFilterChip(
              label: 'Status',
              value: _filterStatus?.name,
              onTap: _showStatusFilter,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'Role',
              value: _filterRole?.name,
              onTap: _showRoleFilter,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'Age Group',
              value: _filterAgeGroup?.name,
              onTap: _showAgeGroupFilter,
            ),
            const SizedBox(width: 16),
            const Text(
              'Sort:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(width: 16),
            _buildSortChip('Last Active', 'lastActive'),
            const SizedBox(width: 8),
            _buildSortChip('Username', 'username'),
            const SizedBox(width: 8),
            _buildSortChip('Points', 'points'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    String? value,
    required VoidCallback onTap,
  }) {
    final hasValue = value != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: hasValue
              ? const Color(0xFF6366F1).withValues(alpha: 0.1)
              : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasValue ? const Color(0xFF6366F1) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hasValue ? '$label: $value' : label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: hasValue
                    ? const Color(0xFF6366F1)
                    : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              hasValue ? Icons.close : Icons.arrow_drop_down,
              size: 18,
              color: hasValue
                  ? const Color(0xFF6366F1)
                  : const Color(0xFF6B7280),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return InkWell(
      onTap: () => setState(() => _sortBy = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // User list
  // ---------------------------------------------------------------------------

  Widget _buildUsersList(List<AdminUserModel> users) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: AdminUserCard(
            user: user,
            onViewDetails: () => context.go('/admin/users/${user.id}'),
            onShowActions: () => _showQuickActions(user),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_outline,
              size: 64,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No users found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your filters or search query',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Filter bottom sheets
  // ---------------------------------------------------------------------------

  void _showStatusFilter() {
    _showFilterSheet(
      title: 'Filter by Status',
      items: UserStatus.values.map((status) {
        return ListTile(
          leading: Icon(Icons.circle, color: getStatusColor(status)),
          title: Text(getStatusText(status)),
          trailing: _filterStatus == status
              ? const Icon(Icons.check, color: Color(0xFF6366F1))
              : null,
          onTap: () {
            setState(() {
              _filterStatus = _filterStatus == status ? null : status;
            });
            Navigator.pop(context);
          },
        );
      }).toList(),
    );
  }

  void _showRoleFilter() {
    _showFilterSheet(
      title: 'Filter by Role',
      items: UserRole.values.map((role) {
        return ListTile(
          leading: Icon(getRoleIcon(role), color: getRoleColor(role)),
          title: Text(getRoleText(role)),
          trailing: _filterRole == role
              ? const Icon(Icons.check, color: Color(0xFF6366F1))
              : null,
          onTap: () {
            setState(() {
              _filterRole = _filterRole == role ? null : role;
            });
            Navigator.pop(context);
          },
        );
      }).toList(),
    );
  }

  void _showAgeGroupFilter() {
    _showFilterSheet(
      title: 'Filter by Age Group',
      items: AgeGroup.values.map((ageGroup) {
        return ListTile(
          leading: Icon(Icons.cake, color: getAgeGroupColor(ageGroup)),
          title: Text(getAgeGroupText(ageGroup)),
          trailing: _filterAgeGroup == ageGroup
              ? const Icon(Icons.check, color: Color(0xFF6366F1))
              : null,
          onTap: () {
            setState(() {
              _filterAgeGroup = _filterAgeGroup == ageGroup ? null : ageGroup;
            });
            Navigator.pop(context);
          },
        );
      }).toList(),
    );
  }

  void _showFilterSheet({
    required String title,
    required List<Widget> items,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ...items,
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Quick actions
  // ---------------------------------------------------------------------------

  void _showQuickActions(AdminUserModel user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Quick Actions - ${user.username}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Color(0xFF6366F1)),
                title: const Text('Edit User'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditUserDialog(user);
                },
              ),
              ListTile(
                leading: Icon(
                  user.isBanned ? Icons.check_circle : Icons.block,
                  color: user.isBanned
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                ),
                title: Text(user.isBanned ? 'Unban User' : 'Ban User'),
                onTap: () {
                  Navigator.pop(context);
                  _toggleBanUser(user);
                },
              ),
              ListTile(
                leading: const Icon(Icons.email, color: Color(0xFF3B82F6)),
                title: const Text('Send Email'),
                onTap: () {
                  Navigator.pop(context);
                  _sendEmail(user);
                },
              ),
              ListTile(
                leading:
                const Icon(Icons.history, color: Color(0xFF6B7280)),
                title: const Text('View Activity Log'),
                onTap: () {
                  Navigator.pop(context);
                  _viewActivityLog(user);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete, color: Color(0xFFEF4444)),
                title: const Text(
                  'Delete User',
                  style: TextStyle(color: Color(0xFFEF4444)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteUser(user);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // User actions
  // ---------------------------------------------------------------------------

  void _toggleBanUser(AdminUserModel user) {
    showCustomAlertDialog(
      context: context,
      title: user.isBanned ? 'Unban User' : 'Ban User',
      message: user.isBanned
          ? 'Are you sure you want to unban ${user.username}?'
          : 'Are you sure you want to ban ${user.username}? This will prevent them from accessing the app.',
      type: user.isBanned ? AlertType.success : AlertType.warning,
      confirmText: user.isBanned ? 'Unban User' : 'Ban User',
      cancelText: 'Cancel',
      onConfirm: () async {
        try {
          final sm = ref.read(serviceManagerProvider);
          if (user.isBanned) {
            await sm.apiService
                .post('/admin/users/${user.id}/unban', body: {});
          } else {
            await sm.apiService.post('/admin/users/${user.id}/ban',
                body: {'reason': 'Admin action'});
          }
          await _loadUsersFromBackend();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(user.isBanned
                ? '${user.username} has been unbanned'
                : '${user.username} has been banned'),
            behavior: SnackBarBehavior.floating,
          ));
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to update ban state: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFEF4444),
          ));
        }
      },
    );
  }

  void _deleteUser(AdminUserModel user) {
    showCustomAlertDialog(
      context: context,
      title: 'Delete User',
      message:
      'Are you sure you want to permanently delete ${user.username}? This action cannot be undone.',
      type: AlertType.delete,
      confirmText: 'Delete User',
      cancelText: 'Cancel',
      onConfirm: () async {
        try {
          final sm = ref.read(serviceManagerProvider);
          await sm.apiService.delete('/admin/users/${user.id}');
          await _loadUsersFromBackend();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${user.username} has been deleted'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFEF4444),
          ));
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to delete user: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFEF4444),
          ));
        }
      },
    );
  }

  void _sendEmail(AdminUserModel user) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Email composer opened for ${user.email}'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _viewActivityLog(AdminUserModel user) async {
    try {
      final serviceManager = ref.read(serviceManagerProvider);
      final response = await serviceManager.apiService.get('/admin/users/${user.id}/activity');
      final items = response['items'];
      final logs = items is List
          ? items
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList()
          : <Map<String, dynamic>>[];
      if (!mounted) return;
      _showActivityLogDialog(user, logs);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to load activity log: $e'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _showActivityLogDialog(
      AdminUserModel user, List<Map<String, dynamic>> logs) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Activity Log • ${user.username}'),
        content: SizedBox(
          width: 500,
          child: logs.isEmpty
              ? const Text('No activity records found.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: logs.length,
                  separatorBuilder: (_, __) => const Divider(height: 12),
                  itemBuilder: (_, i) {
                    final log = logs[i];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(log['type']?.toString() ?? 'UNKNOWN',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(log['description']?.toString() ?? '-'),
                        const SizedBox(height: 4),
                        Text(log['createdAt']?.toString() ?? '-',
                            style: const TextStyle(
                                color: Color(0xFF6B7280), fontSize: 12)),
                      ],
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Dialogs
  // ---------------------------------------------------------------------------

  void _showAddUserDialog() {
    final usernameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    UserRole selectedRole = UserRole.user;
    AgeGroup selectedAge = AgeGroup.adults;
    bool isVerified = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usernameCtrl,
                  decoration:
                  const InputDecoration(labelText: 'Username'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailCtrl,
                  decoration:
                  const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passwordCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Temporary Password'),
                  obscureText: true,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<UserRole>(
                  value: selectedRole,
                  items: UserRole.values
                      .map((r) => DropdownMenuItem(
                      value: r, child: Text(getRoleText(r))))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedRole = v);
                  },
                  decoration:
                  const InputDecoration(labelText: 'Role'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<AgeGroup>(
                  value: selectedAge,
                  items: AgeGroup.values
                      .map((a) => DropdownMenuItem(
                      value: a, child: Text(getAgeGroupText(a))))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedAge = v);
                  },
                  decoration:
                  const InputDecoration(labelText: 'Age Group'),
                ),
                const SizedBox(height: 6),
                SwitchListTile(
                  value: isVerified,
                  onChanged: (v) =>
                      setDialogState(() => isVerified = v),
                  title: const Text('Verified'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final username = usernameCtrl.text.trim();
                final email = emailCtrl.text.trim();
                final tempPassword = passwordCtrl.text.trim();
                if (username.isEmpty ||
                    email.isEmpty ||
                    tempPassword.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text(
                        'Username, email and temporary password are required.'),
                  ));
                  return;
                }
                try {
                  final sm = ref.read(serviceManagerProvider);
                  await sm.apiService.post('/admin/users', body: {
                    'username': username,
                    'email': email,
                    'role': selectedRole.name,
                    'ageGroup': selectedAge.name,
                    'isVerified': isVerified,
                    'temporaryPassword': tempPassword,
                  });
                  if (!mounted) return;
                  Navigator.pop(context);
                  await _loadUsersFromBackend();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('User created successfully'),
                    behavior: SnackBarBehavior.floating,
                  ));
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Failed to create user: $e'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: const Color(0xFFEF4444),
                  ));
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditUserDialog(AdminUserModel user) {
    UserRole selectedRole = user.role;
    bool verified = user.isVerified;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit ${user.username}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<UserRole>(
                value: selectedRole,
                items: UserRole.values
                    .map((r) => DropdownMenuItem(
                    value: r, child: Text(getRoleText(r))))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => selectedRole = v);
                },
                decoration: const InputDecoration(labelText: 'Role'),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: verified,
                title: const Text('Verified'),
                onChanged: (v) =>
                    setDialogState(() => verified = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final sm = ref.read(serviceManagerProvider);
                  await sm.apiService.patch('/admin/users/${user.id}',
                      body: {
                        'role': selectedRole.name,
                        'isVerified': verified,
                      });
                  if (!mounted) return;
                  Navigator.pop(context);
                  await _loadUsersFromBackend();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('User updated'),
                    behavior: SnackBarBehavior.floating,
                  ));
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Failed to update user: $e'),
                  ));
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
